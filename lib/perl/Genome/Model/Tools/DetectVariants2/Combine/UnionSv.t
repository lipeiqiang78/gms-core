#!/usr/bin/env genome-perl

use strict;
use warnings;

use above "Genome";
use Test::More;
use File::Compare;

$ENV{UR_DBI_NO_COMMIT} = 1;
$ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;

BEGIN {
    my $archos = `uname -a`;
    if ($archos !~ /64/) {
        plan skip_all => "Must run from 64-bit machine";
    }
};

use_ok( 'Genome::Model::Tools::DetectVariants2::Combine::UnionSv');

my $test_data_dir     = $ENV{GENOME_TEST_INPUTS} . '/Genome-Model-Tools-DetectVariants2-Combine-UnionSv';
is(-d $test_data_dir, 1, 'test_data_dir exists') || die;

my $expected_output   = $test_data_dir . '/expected_output_dir';
is(-d $expected_output, 1, 'expected_output exists') || die;

# FIXME Swap this for a test constructed reference build.
my $reference_build = Genome::Model::Build->get(109104543);
ok($reference_build, 'got reference_build');

my $aligned_reads         = join('/', $test_data_dir, 'tumor.bam');
my $control_aligned_reads = join('/', $test_data_dir, 'normal.bam');

my $detector_name_a = 'Genome::Model::Tools::DetectVariants2::Breakdancer';
my $detector_version_a = 'awesome';
my $output_dir_a = join('/', $test_data_dir, 'breakdancer_inter_tigra');
my $detector_a = Genome::Model::Tools::DetectVariants2::Result->__define__(
    output_dir            => $output_dir_a,
    reference_build       => $reference_build,
    detector_name         => $detector_name_a,
    detector_version      => $detector_version_a,
    detector_params       => '',
    aligned_reads         => $aligned_reads,
    control_aligned_reads => $control_aligned_reads,
);
$detector_a->lookup_hash($detector_a->calculate_lookup_hash());
isa_ok($detector_a, 'Genome::Model::Tools::DetectVariants2::Result', 'detector_a');

my $detector_name_b    = 'Genome::Model::Tools::DetectVariants2::Breakdancer';
my $detector_version_b = 'awesome';
my $output_dir_b = join('/', $test_data_dir, 'breakdancer_intra_tigra');
my $detector_b = Genome::Model::Tools::DetectVariants2::Result->__define__(
    output_dir            => $output_dir_b,
    reference_build       => $reference_build,
    detector_name         => $detector_name_b,
    detector_version      => $detector_version_b,
    detector_params       => '',
    aligned_reads         => $aligned_reads,
    control_aligned_reads => $control_aligned_reads,
);
$detector_b->lookup_hash($detector_b->calculate_lookup_hash());
isa_ok($detector_b, 'Genome::Model::Tools::DetectVariants2::Result', 'detector_b');

my $test_output_dir = File::Temp::tempdir('Genome-Model-Tools-DetectVariants2-Combine-UnionSv-XXXXX', DIR => "$ENV{GENOME_TEST_TEMP}", CLEANUP => 1);
my $output_symlink  = join('/', $test_output_dir, 'intersect-snv');
my $union_sv_object = Genome::Model::Tools::DetectVariants2::Combine::UnionSv->create(
    input_a_id => $detector_a->id,
    input_b_id => $detector_b->id,
    output_directory => $output_symlink,
);

ok($union_sv_object, 'created UnionSv object');
ok($union_sv_object->execute(), 'executed UnionSv object');

my @files = ('svs.hq', 'svs.hq.merge.annot.somatic');
for my $type qw(Inter Intra) {
    push @files, map{$type.'.svs.merge.'.$_}qw(fasta file out file.annot);
}

for my $file (@files) {
    my $test_output     = $output_symlink.'/'.$file;
    my $expected_output = $expected_output.'/'.$file;
    system("diff -u $expected_output $test_output");
    is(compare($test_output,$expected_output),0, "Found no difference for $file between test and expected output");
}

done_testing();
