
package Genome::Model::Tools::Galaxy::GenerateConfig;

use strict;
use warnings;
use Genome;

class Genome::Model::Tools::Galaxy::GenerateConfig {
    is  => 'Command',
    has => [
        tools => {
            is  => 'Text',
            is_many => 1,
            shell_args_position => 1,
            doc => 'the name(s) of the GMT class(es) for which to generate a tool',
        },
    ],
    doc => 'generate a .galaxy.xml file for any tool in GMT'
};

sub execute {
    my $self = shift;

    # self-referencing subroutine must have the variable declared before the sub
    my $expand_sub_commands; 
    $expand_sub_commands = sub {
        my @expanded = ();
        for my $class_name (@_) {
            if ($class_name->isa("Command::Tree")) {
                my @sub = $class_name->sub_command_classes;
                push @expanded, $expand_sub_commands->(@sub);
            }
            else {
                push @expanded, $class_name;
            }
        }
        return @expanded;
    };

    my @class_names = $expand_sub_commands->($self->tools); 
    
    # elimiate circular reference to prevent memory leak
    $expand_sub_commands = undef;

    for my $class_name (@class_names) {
        $self->debug_message("handling $class_name...");

        do {
            eval "use " . $class_name;
            if ($@) {
                die "Failed to use module $class_name:\n$@";
            }
        };

        my $class_meta = $class_name->__meta__;
        if ( !$class_meta ) {
            $self->error_message("Invalid command class: $class_name");
            return 0;
        }
        
        my $inputs = '';
        my $outputs = '';
        my $command = $class_name->command_name;
        
        # get only direct attributions which aren't auto-generated by more complex ones
        my @attrs = $class_meta->properties(implied_by => undef); 

        # iterate through and check for input/output files
        # we build the galaxy <inputs> and <outputs> sections as we go
        foreach my $sub_hsh (@attrs) {
            my $attr = $sub_hsh->property_name;
            my $dash_attr = $attr;
            $dash_attr =~ s/_/-/g;
            my $is_bool = 0;

            my $file_format = $sub_hsh->{file_format};
            if (($sub_hsh->{is_input} || $sub_hsh->{is_output}) and !defined($file_format)) {
                # lets warn them about not defining a file_format on an input or output file
                $self->warning_message("Input or output file_format is not defined on attribute $attr. Falling back to 'text'");
                $file_format = 'text';
            }
            if ($sub_hsh->{is_output} && $attr ne 'result')
            {
                $outputs .= '<data name="'.$attr.'" format="'.$file_format.'" label="" help="" />' . "\n";
                #check for dir in name i guess?
            }
            elsif ($sub_hsh->{is_input})
            {
              if($sub_hsh->{valid_values})
              {
                $inputs .= '<param name="'.$attr.'" format="'.$file_format.'" type="select" help="">' . "\n";
                for(@{$sub_hsh->{valid_values}}){
                    $inputs .= "  <option value='" . $_ . "'>". $_ ."</option>\n";
                  }
                $inputs .= "</param>\n";
              } elsif($sub_hsh->{data_type} eq "Boolean" ){
                $is_bool = 1;
                my $check = $sub_hsh->{default} ? "True" : "False";
                $inputs .= '<param name="'.$attr.'" format="'.$file_format.'" type="data" help="" checked="'. $check .'" truevalue="--' . $dash_attr . '" falsevalue="--no' . $dash_attr . '"/>' . "\n";
              } elsif($sub_hsh->{default}) {

              } else {
                $inputs .= '<param name="'.$attr.'" format="'.$file_format.'" type="data" help="" />' . "\n";
              }
            }
            if(($sub_hsh->{is_input} || $sub_hsh->{is_output}) && $attr ne 'result')
            {
              $command .= $is_bool ? "\$$attr " : " --$dash_attr=\$$attr ";
            }
        }

        my $help_brief  = $class_name->help_brief;
        my $help_detail = do {
            local $ENV{ANSI_COLORS_DISABLED} = 1;
            $class_name->help_usage_complete_text;
        };

        my $tool_id = $class_name->command_name;
        $tool_id =~ s/ /_/g;

        # galaxy will bold headers surrounded by * like **THIS**
        $help_detail =~ s/^([A-Z]+[A-Z ]+:?)/\n**$1**\n/mg;

        my $xml = <<"XML";
<tool id="$tool_id" name="$tool_id">
    <description>
        $help_brief
    </description>
    <command>
        $command
    </command>
    <inputs>
        $inputs
    </inputs>
    <outputs>
        $outputs
    </outputs>
    <help>
        $help_detail
    </help>
</tool>
XML
        my $module_name = $class_name;
        $module_name =~ s|::|/|g;
        $module_name .= '.pm';

        my $module_path = $INC{$module_name};
        if (not $module_path) {
            $self->error_message("Failed to find the path for module $module_name!");
        }

        my $config_path = $module_path . '.galaxy.xml';

        if (-e $config_path) {
            $self->debug_message("Moving the old $config_path to .bak...");
            rename($config_path, "$config_path.bak") or die "Failed to rename $config_path to $config_path.bak! $!";
        }

        $self->debug_message("writing $config_path");
        Genome::Sys->write_file($config_path, $xml);
    }

    return 1
}

sub bin_properties {
    my ($properties, %spec) = @_;
    
    my %output = map { $_ => [] } keys %spec;
    foreach my $p (@$properties) {
        my @matched = grep {
            $spec{$_}->($p)
        } keys %spec;
        
        for (@matched) {
            push @{ $output{$_} }, $p;
        }
    }

    return %output;
}

