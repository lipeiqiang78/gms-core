package Genome::Model::Tools::EpitopePrediction::GetWildtype;

use strict;
use warnings;

use Genome;
use Workflow;
class Genome::Model::Tools::EpitopePrediction::GetWildtype {
    is => ['Genome::Model::Tools::EpitopePrediction::Base'],
    has_input => [
        input_tsv_file => {
        	is => 'Text',
            doc => 'A tab separated input file from the annotator',
        },
        output_tsv_file => {
            is => 'Text',
            is_output=> 1,
            doc => 'A tab separated output file with the amino acid sequences both wildtype and mutant',
        },
        anno_db => {
            is => 'Text',
            is_optional=> 1,
            doc => 'The name of the annotation database.  Example: NCBI-human.combined-annotation',
        },
        
        version => {
            is => 'Text',
            is_optional=> 1,
            doc => 'The version of the annotation database. Example: 54_36p_v2',
        },
    ],
};

sub help_brief {
    "Get the Wildtype protein sequence from the specified Annotation Database for the variant proteins which have been annotated",
}


sub execute {
    my $self = shift;
    my $input = $self->input_tsv_file;
    my $output = $self->output_tsv_file;

#TODO : Check if the file has header 
	
	unless (Genome::Model::Tools::Annotate::VariantProtein ->execute
  			 	(
   					input_tsv_file => $input,
   					output_tsv_file => $output,
   					anno_db 		=> $self->anno_db,
   					version 		=> $self->version
   				)
   			)
   			{die;}
    
	
    
    return 1;   
}

1;

__END__
gmt annotate variant-protein 
--input-tsv-file=Shared-Somatic-Tier1-Missense-d42m1.fullAnnotation_withHeader.tsv 
--output-tsv-file=Shared-Somatic-Tier1-Missense-d42m1.fullAnnotation_withHeader_WT.tsv 
--anno-db=NCBI-mouse.combined-annotation --version=58_37k_v2