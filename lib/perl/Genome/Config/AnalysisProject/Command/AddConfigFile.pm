package Genome::Config::AnalysisProject::Command::AddConfigFile;

use strict;
use warnings;

use Genome;

class Genome::Config::AnalysisProject::Command::AddConfigFile {
    is => 'Command::V2',
    has_input => [
       analysis_project  => {
            is                  => 'Genome::Config::AnalysisProject',
            doc                 => 'the analysis project to add the config file to',
            shell_args_position => 1,
        },
       config_file  => {
            is                  => 'Path',
            doc                 => 'path to the config file',
            shell_args_position => 2,
        },
        store_only => {
            is => 'Boolean',
            doc => 'If set, the config file will only be stored (it will not be used for processing).  Defaults to 0',
            default_value => 0,
        },
    ],
};

sub help_brief {
    return 'add a yml config file to an existing analysis project';
}

sub help_synopsis {
    return "genome config analysis-project add-config-config-file <analysis-project> <file-path>";
}

sub help_detail {
    return <<"EOS"
Given an analysis project and a config file, this will associate the two
EOS
}

sub execute {
    my $self = shift;
    my $status = $self->store_only ? 'disabled' : 'active';

    return Genome::Config::Profile::Item->create_from_file_path(
        file_path => $self->config_file,
        analysis_project => $self->analysis_project,
        status => $status,
    );
}

1;
