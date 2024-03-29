package Genome::Annotation::TestHelpers;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use strict;
use warnings;

use above 'Genome';
use Test::More;
use Sub::Install qw(reinstall_sub);
use Set::Scalar;
use Params::Validate qw(validate validate_pos :types);
use Genome::Test::Factory::Model::SomaticVariation;
use Genome::Test::Factory::InstrumentData::Solexa;
use Genome::Test::Factory::InstrumentData::MergedAlignmentResult;
use Genome::Utility::Test;
use File::Slurp qw(write_file);
use Genome::Utility::Test qw(compare_ok);

use Exporter 'import';

our @EXPORT_OK = qw(
    test_cmd_and_result_are_in_sync
    get_test_somatic_variation_build
    get_test_somatic_variation_build_from_files
    get_test_dir
    test_dag_xml
    test_dag_execute
);

sub test_cmd_and_result_are_in_sync {
    my $cmd = shift;

    my $cmd_set = Set::Scalar->new($cmd->input_names);
    my $sr_set = Set::Scalar->new($cmd->output_result->param_names,
        $cmd->output_result->metric_names, $cmd->output_result->input_names);
    is_deeply($cmd_set - $sr_set, Set::Scalar->new(),
        'All command inputs are persisted SoftwareResult properties');
}

sub get_test_somatic_variation_build {
    my %p = validate(@_, {
        version => {type => SCALAR},
    });

    my $test_dir = get_test_dir('Genome::Annotation::Expert::Base', $p{version});

    return get_test_somatic_variation_build_from_files(
        bam1 => File::Spec->join($test_dir, 'bam1.bam'),
        bam2 => File::Spec->join($test_dir, 'bam2.bam'),
        reference_fasta => File::Spec->join($test_dir, 'reference.fasta'),
        snvs_vcf => File::Spec->join($test_dir, 'snvs.vcf.gz'),
        indels_vcf => File::Spec->join($test_dir, 'indels.vcf.gz'),
    );
}

sub get_test_somatic_variation_build_from_files {
    my %p = validate(@_, {
        bam1 => {type => SCALAR},
        bam2 => {type => SCALAR},
        reference_fasta => {type => SCALAR},
        snvs_vcf => {type => SCALAR},
        indels_vcf => {type => SCALAR},
    });

    my ($bam_result1, $bam_result2) = setup_bam_results($p{bam1}, $p{bam2},
        $p{reference_fasta});
    my ($snvs_result, $indels_result) = setup_vcf_results($p{snvs_vcf},
        $p{indels_vcf});
    my %params = (
        bam_result1 => $bam_result1,
        bam_result2 => $bam_result2,
        snvs_vcf_result => $snvs_result,
        indels_vcf_result => $indels_result,
    );

    my $build = setup_build(%params);

    reinstall_sub( {
        into => $build->reference_sequence_build->class,
        as => 'fasta_file',
        code => sub { return $p{reference_fasta}; },
    });

    return $build;
}

sub setup_build {
    my %p = validate(@_, {
        bam_result1 => {type => OBJECT},
        bam_result2 => {type => OBJECT},
        snvs_vcf_result => {type => OBJECT},
        indels_vcf_result => {type => OBJECT},
    });
    my $build = Genome::Test::Factory::Model::SomaticVariation->setup_somatic_variation_build;

    $build->tumor_build->subject->name('TEST-patient1-somval_tumor1');

    my %build_to_result = (
        $build->tumor_build->id => $p{bam_result1},
        $build->normal_build->id => $p{bam_result2},
    );
    reinstall_sub( {
        into => $build->normal_build->class,
        as => 'merged_alignment_result',
        code => sub {my $self = shift;
            return $build_to_result{$self->id};
        },
    });

    reinstall_sub({
        into => "Genome::Model::Build::RunsDV2",
        as => "get_detailed_snvs_vcf_result",
        code => sub { my $self = shift;
                      return $p{snvs_vcf_result};
        },
    });
    reinstall_sub({
        into => "Genome::Model::Build::RunsDV2",
        as => "get_detailed_indels_vcf_result",
        code => sub { my $self = shift;
                      return $p{indels_vcf_result};
        },
    });
    return $build;
}

sub setup_vcf_results {
    my ($snvs_vcf, $indels_vcf) = validate_pos(@_, 1, 1);
    my $snv_vcf_result = Genome::Model::Tools::DetectVariants2::Result::Vcf::Combine->__define__;
    my $indel_vcf_result = Genome::Model::Tools::DetectVariants2::Result::Vcf::Combine->__define__;

    my %result_to_vcf_file = (
        $snv_vcf_result->id => $snvs_vcf,
        $indel_vcf_result->id => $indels_vcf,
    );
    reinstall_sub( {
        into => 'Genome::Model::Tools::DetectVariants2::Result::Vcf::Combine',
        as => 'get_vcf',
        code => sub {my $self = shift;
            return $result_to_vcf_file{$self->id};
        },
    });

    return ($snv_vcf_result, $indel_vcf_result);
}

sub setup_bam_results {
    my ($bam1, $bam2, $reference_fasta) = validate_pos(@_, 1, 1, 1);
    my $bam_result1 = Genome::Test::Factory::InstrumentData::MergedAlignmentResult->setup_object();
    my $bam_result2 = Genome::Test::Factory::InstrumentData::MergedAlignmentResult->setup_object();

    my %bam_result_to_sample_name = (
        $bam_result1->id => get_sample_name($bam1),
        $bam_result2->id => get_sample_name($bam2),
    );
    reinstall_sub( {
        into => 'Genome::InstrumentData::AlignmentResult::Merged',
        as => 'sample_name',
        code => sub {my $self = shift;
            return $bam_result_to_sample_name{$self->id};
        },
    });


    my %result_to_bam_file = (
        $bam_result1->id => $bam1,
        $bam_result2->id => $bam2,
    );
    reinstall_sub( {
        into => 'Genome::InstrumentData::AlignmentResult::Merged',
        as => 'bam_file',
        code => sub {my $self = shift;
            return $result_to_bam_file{$self->id};
        },
    });
    reinstall_sub( {
        into => 'Genome::InstrumentData::AlignmentResult::Merged',
        as => 'reference_fasta',
        code => sub {return $reference_fasta;},
    });

    return ($bam_result1, $bam_result2);
}

sub get_sample_name {
    my $bam = shift;
    my $cmd = Genome::Model::Tools::Sam::GetSampleName->execute(bam_file => $bam);
    return $cmd->sample_name;
}

sub test_dag_xml {
    my ($dag, $expected_xml) = @_;
    my $xml_path = Genome::Sys->create_temp_file_path;
    write_file($xml_path, $dag->get_xml);
    compare_ok($expected_xml, $xml_path, "Xml looks as expected");
}

sub test_dag_execute {
    my ($dag, $expected_vcf, $variant_type, $build, $plan) = @_;
    my $accessor = sprintf("get_detailed_%s_vcf_result", $variant_type);
    my $output = $dag->execute(
        input_result => $build->$accessor,
        build_id => $build->id,
        variant_type => $variant_type,
        plan_json => $plan->as_json,
    );
    my $vcf_path = $output->{output_result}->output_file_path;
    my $differ = Genome::File::Vcf::Differ->new($vcf_path, $expected_vcf);
    my $diff = [$differ->diff];
    is_deeply($diff, [], "Found No differences between $vcf_path and (expected) $expected_vcf") or
        diag Data::Dumper::Dumper($diff);
}

sub get_test_dir {
    my ($pkg, $VERSION) = validate_pos(@_, 1, 1);

    my $test_dir = Genome::Utility::Test->data_dir($pkg, "v$VERSION");
    if (-d $test_dir) {
        note "Found test directory ($test_dir)";
    } else {
        die "Failed to find test directory ($test_dir)";
    }
    return $test_dir;
}
