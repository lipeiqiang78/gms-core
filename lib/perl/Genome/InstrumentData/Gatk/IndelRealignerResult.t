#! /gsc/bin/perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above 'Genome';

require Genome::Utility::Test;
use Test::More;

my $class = 'Genome::InstrumentData::Gatk::IndelRealignerResult';
use_ok($class) or die;
my $result_data_dir = Genome::Utility::Test->data_dir_ok($class, 'v1');

# Inputs
use_ok('Genome::InstrumentData::Gatk::Test') or die;
my $gatk_test = Genome::InstrumentData::Gatk::Test->get;
my $bam_source = $gatk_test->bam_source;
my $reference_build = $gatk_test->reference_build;
my %params = (
    version => 2.4,
    bam_source => $bam_source,
    reference_build => $reference_build,
    known_sites => [ $gatk_test->known_site ],
);

# Get [fails as expected]
my $indel_realigner = Genome::InstrumentData::Gatk::IndelRealignerResult->get_with_lock(%params);
ok(!$indel_realigner, 'Failed to get existing gatk indel realigner result');

# Create
$indel_realigner = Genome::InstrumentData::Gatk::IndelRealignerResult->get_or_create(%params);
ok($indel_realigner, 'created gatk indel realigner');

# Outputs
is($indel_realigner->intervals_file, $indel_realigner->output_dir.'/'.$bam_source->id.'.bam.intervals', 'intervals file named correctly');
ok(-s $indel_realigner->intervals_file, 'intervals file exists');
Genome::Utility::Test::compare_ok($indel_realigner->intervals_file, $result_data_dir.'/expected.bam.intervals', 'intervals file matches');
is($indel_realigner->bam_path, $indel_realigner->output_dir.'/'.$indel_realigner->id.'.bam', 'bam file named correctly');
ok(-s $indel_realigner->bam_path, 'bam file exists');#bam produced fin test is the same except for the knowns file in the header
ok(-s $indel_realigner->bam_path.'.bai', 'bam index exists');
ok(-s $indel_realigner->bam_flagstat_file, 'bam flagstat file exists');
Genome::Utility::Test::compare_ok($indel_realigner->bam_flagstat_file, $result_data_dir.'/expected.bam.flagstat', 'flagstat matches');
ok(-s $indel_realigner->bam_md5_path, 'bam md5 path exists');

# Users
my @bam_source_users = $bam_source->users;
ok(@bam_source_users, 'add users to bam source');
is_deeply([map { $_->label } @bam_source_users], ['bam source'], 'bam source user haver correct label');
my @users = sort { $a->id <=> $b->id } map { $_->user } @bam_source_users;
is_deeply(\@users, [$indel_realigner], 'bam source is used by indel realigner result');

# Allocation params
is(
    $indel_realigner->resolve_allocation_disk_group_name,
    $ENV{GENOME_DISK_GROUP_MODELS},
    'resolve_allocation_disk_group_name',
);
is(
    $indel_realigner->resolve_allocation_kilobytes_requested,
    34,
    'resolve_allocation_kilobytes_requested',
);
like(
    $indel_realigner->resolve_allocation_subdirectory,
    qr(^model_data/gatk/indel_realigner-),
    'resolve_allocation_subdirectory',
);

#print $indel_realigner->_tmpdir."\n";
#print $indel_realigner->output_dir."\n"; <STDIN>;
done_testing();
