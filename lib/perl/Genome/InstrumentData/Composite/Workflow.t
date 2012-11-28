#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT}               = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
}

use Test::More tests => 10;

use above "Genome";

use_ok('Genome::InstrumentData::Composite::Workflow')
  or die('test cannot continue');

my $sample = Genome::Sample->__define__(
    id => '-100',
    name => 'sample',
);

my $instrument_data_1 = Genome::InstrumentData::Solexa->__define__(
    flow_cell_id => '12345ABXX',
    lane => '1',
    subset_name => '1',
    run_name => 'example',
    id => '-23',
    sample => $sample,
);
my $instrument_data_2 = Genome::InstrumentData::Solexa->__define__(
    flow_cell_id => '12345ABXX',
    lane => '2',
    subset_name => '2',
    run_name => 'example',
    id => '-24',
    sample => $sample,
);

my @instrument_data = ($instrument_data_1, $instrument_data_2);

my $ref = Genome::Model::Build::ReferenceSequence->get_by_name('GRCh37-lite-build37');

my %params_for_result = (
    aligner_name => 'bwa',
    aligner_version => '0.5.9',
    aligner_params => '-t 4 -q 5::',
    samtools_version => 'r599',
    picard_version => '1.29',
    reference_build_id => $ref->id,
);

my @results;
for my $i (@instrument_data) {
    my $r = Genome::InstrumentData::AlignmentResult::Bwa->__define__(
        %params_for_result,
        instrument_data_id => $i->id,
    );
    $r->lookup_hash($r->calculate_lookup_hash());
    push @results, $r;
}


my $sample_2 = Genome::Sample->create(
    name => 'sample2',
    id => '-101',
);

my $instrument_data_3 = Genome::InstrumentData::Solexa->__define__(
        flow_cell_id => '12345ABXX',
        lane => '3',
        subset_name => '3',
        run_name => 'example',
        id => '-28',
        sample => $sample_2,
    );
my $result_3 = Genome::InstrumentData::AlignmentResult::Bwa->__define__(
    %params_for_result,
    instrument_data_id => $instrument_data_3->id,
);
$result_3->lookup_hash($result_3->calculate_lookup_hash());

my $merge_result2 = construct_merge_result($instrument_data_3);

my $log_directory = Genome::Sys->create_temp_directory();
my $ad = Genome::InstrumentData::Composite::Workflow->create(
    inputs => {
        inst => \@instrument_data,
        ref => $ref,
        force_fragment => 0,
    },
    strategy => 'inst aligned to ref using bwa 0.5.9 [-t 4 -q 5::] api v1',
    log_directory => $log_directory,
);
isa_ok(
    $ad,
    'Genome::InstrumentData::Composite::Workflow',
    'created dispatcher for simple alignments'
);


ok($ad->execute, 'executed dispatcher for simple alignments');

my @ad_result_ids = $ad->_result_ids;
my @ad_results = Genome::SoftwareResult->get(\@ad_result_ids);
is_deeply([sort @results], [sort @ad_results], 'found expected alignment results');

my $merge_result = construct_merge_result(@instrument_data);

my $ad2 = Genome::InstrumentData::Composite::Workflow->create(
    inputs => {
        inst => \@instrument_data,
        ref => $ref,
        force_fragment => 0,
    },
    strategy => 'inst aligned to ref using bwa 0.5.9 [-t 4 -q 5::] then merged using picard 1.29 then deduplicated using picard 1.29 api v1',
);
isa_ok(
    $ad2,
    'Genome::InstrumentData::Composite::Workflow',
    'created dispatcher for simple alignments with merge'
);

ok($ad2->execute, 'executed dispatcher for simple alignments with merge');
my @ad2_result_ids = $ad2->_result_ids;
my @ad2_results = Genome::SoftwareResult->get(\@ad2_result_ids);
is_deeply([sort @results, $merge_result], [sort @ad2_results], 'found expected alignment and merge results');


push @instrument_data, $instrument_data_3;
push @results, $result_3;

my $ad3 = Genome::InstrumentData::Composite::Workflow->create(
    inputs => {
        inst => \@instrument_data,
        ref => $ref,
        force_fragment => 0,
    },
    strategy => 'inst aligned to ref using bwa 0.5.9 [-t 4 -q 5::] then merged using picard 1.29 then deduplicated using picard 1.29 api v1',
);
isa_ok(
    $ad3,
    'Genome::InstrumentData::Composite::Workflow',
    'created dispatcher for simple alignments of different samples with merge'
);

ok($ad3->execute, 'executed dispatcher for simple alignments of different samples with merge');
my @ad3_result_ids = $ad3->_result_ids;
my @ad3_results = Genome::SoftwareResult->get(\@ad3_result_ids);
is_deeply([sort @results, $merge_result, $merge_result2], [sort @ad3_results], 'found expected alignment and merge results');




sub construct_merge_result {
    my @id = @_;

    my $merge_result = Genome::InstrumentData::AlignmentResult::Merged->__define__(
        %params_for_result,
        merger_name => 'picard',
        merger_version => '1.29',
        duplication_handler_name => 'picard',
        duplication_handler_version => '1.29',
    );
    $merge_result->lookup_hash($merge_result->calculate_lookup_hash());
    for my $i (0..$#id) {
        $merge_result->add_input(
            name => 'instrument_data_id-' . $i,
            value_id => $id[$i]->id,
        );
    }
    $merge_result->add_param(
        name => 'instrument_data_id_count',
        value_id=> scalar(@id),
    );
    $merge_result->add_param(
        name => 'instrument_data_id_md5',
        value_id => Genome::Sys->md5sum_data(join(':', sort(map($_->id, @id))))
    );

    $merge_result->add_param(
        name => 'filter_name_count',
        value_id => 0,
    );
    $merge_result->add_param(
        name => 'instrument_data_segment_count',
        value_id => 0,
    );

    return $merge_result;
}
