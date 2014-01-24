#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use above 'Genome';

use Test::More;

use_ok('Genome::Model::Command::Services::AssignQueuedInstrumentData') or die;

my ($cnt, @samples, @instrument_data);
no warnings;
*Genome::InstrumentDataAttribute::get = sub {
    my ($class, %params) = @_;
    my %attrs = map { $_->id => $_ } map { $_->attributes } @instrument_data;
    for my $param_key ( keys %params ) {
        my @param_values = ( ref $params{$param_key} ? @{$params{$param_key}} : $params{$param_key} );
        my @unmatched_attrs;
        for my $attr ( values %attrs ) {
            next if grep { $attr->$param_key eq $_ } @param_values;
            push @unmatched_attrs, $attr->id;
        }
        for ( @unmatched_attrs ) { delete $attrs{$_} }
    }
    return values %attrs;
};
use warnings;

my $source = Genome::Individual->__define__(
    name => '__TEST_HUMAN1_SOURCE__', 
    taxon => Genome::Taxon->__define__(name => 'human', domain => 'Eukaryota', species_latin_name => 'H. sapiens'),
);
ok($source, 'define source');
ok($source->taxon, 'define source taxon');
ok(_create_inst_data($source), 'create inst data for bacteria taxon');
is(@instrument_data, $cnt, "create $cnt inst data");
is_deeply(
    [ map { $_->attribute_value } map { $_->attributes(attribute_label => 'tgi_lims_status') } @instrument_data ],
    [ map { 'new' } @instrument_data ],
    'set tgi lims status to new',
);

my $cmd = Genome::Model::Command::Services::AssignQueuedInstrumentData->create;
ok($cmd, 'create aqid');
ok($cmd->execute, 'execute');
my @new_models = values %{$cmd->_newly_created_models};
my %new_models = _model_hash(@new_models);
#print Data::Dumper::Dumper(\%new_models);
is_deeply(
    \%new_models,
    {
        "AQID-testsample1.human.prod-microarray.wugc.infinium.NCBI-human-build36" => {
            subject => $samples[0]->name,
            processing_profile_id => 2575175,
            inst => [ $instrument_data[0]->id ],
            auto_assign_inst_data => 0,
        },
        "AQID-testsample1.human.prod-microarray.wugc.infinium.GRCh37-lite-build37" => {
            subject => $samples[0]->name,
            processing_profile_id => 2575175,
            inst => [ $instrument_data[0]->id ],
            auto_assign_inst_data => 0,
        },
    },
    'new models',
);
is_deeply(
    [ map { $_->attribute_value } map { $_->attributes(attribute_label => 'tgi_lims_status') } @instrument_data ],
    [ map { 'processed' } @instrument_data ],
    'set tgi lims status to processed',
);
is_deeply(
    [ map { $_->attribute_value } map { $_->attributes(attribute_label => 'tgi_lims_status') } @instrument_data ],
    [ map { 'processed' } @instrument_data ],
    'set tgi lims status to processed for all instrument data',
);

done_testing();


sub _create_inst_data {
    my $source = shift;
    $cnt++;
    my $sample = Genome::Sample->__define__(
        name => 'AQID-testsample'.$cnt.'.'.lc($source->taxon->name),
        source => $source,
        extraction_type => 'genomic',
    );
    ok($sample, 'sample '.$cnt);
    push @samples, $sample;
    my $library = Genome::Library->__define__(
        name => $sample->name.'-testlib',
        sample_id => $sample->id,
    );
    ok($library, 'create library '.$cnt);

    my $instrument_data = Genome::InstrumentData::Imported->__define__(
        library_id => $library->id,
        sequencing_platform => 'infinium',
        import_format => 'genotype file',
        import_source_name => 'wugc',
    );
    ok($instrument_data, 'created instrument data '.$cnt);
    push @instrument_data, $instrument_data;
    $instrument_data->add_attribute(
        attribute_label => 'tgi_lims_status',
        attribute_value => 'new',
    );

    return 1;
}

sub _model_hash {
    return map { 
        $_->name => { 
            subject => $_->subject_name, 
            processing_profile_id => $_->processing_profile_id,
            inst => [ map { $_->id } $_->instrument_data ],
            auto_assign_inst_data => $_->auto_assign_inst_data,
        }
    } @_;
}