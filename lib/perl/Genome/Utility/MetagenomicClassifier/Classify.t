#!/usr/bin/env genome-perl

use strict;
use warnings;

use above "Genome";
use Test::More tests => 12;
use Genome::Utility::MetagenomicClassifier::ChimeraClassifier;

use Bio::Seq;

my $cc_broad = Genome::Utility::MetagenomicClassifier::ChimeraClassifier->create(
        training_set => 'broad',
    );
    ok($cc_broad, 'Created chimera classifier');

    my $seq = Bio::Seq->new( 
        -display_id => 'S000002017 Pirellula staleyi', 
        -seq => 'AATGAACGTTGGCGGCATGGATTAGGCATGCAAGTCGTGCGCGATATGTAGCAATACATGGAGAGCGGCGAAAGGGAGAGTAATACGTAGGAACCTACCTTCGGGTCTGGGATAGCGGCGGGAAACTGCCGGTAATACCAGATGATGTTTCCGAACCAAAGGTGTGATTCCGCCTGAAGAGGGGCCTACGTCGTATTAGCTAGTTGGTAGGGTAATGGCCTACCAAGnCAAAGATGCGTATGGGGTGTGAGAGCATGCCCCCACTCACTGGGACTGAGACACTGCCCAGACACCTACGGGTGGCTGCAGTCGAGAATCTTCGGCAATGGGCGAAAGCCTGACCGAGCGATGCCGCGTGCGGGATGAAGGCCTTCGGGTTGTAAACCGCTGTCGTAGGGGATGAAGTGCTAGGGGGTTCTCCCTCTAGTTTGACTGAACCTAGGAGGAAGGnCCGnCTAATCTCGTGCCAGCAnCCGCGGTAATACGAGAGGCCCAnACGTTATTCGGATTTACTGGGCTTAAAGAGTTCGTAGGCGGTCTTGTAAGTGGGGTGTGAAATCCCTCGGCTCAACCGAGGAACTGCGCTCCAnACTACAAGACTTGAGGGGGATAGAGGTAAGCGGAACTGATGGTGGAGCGGTGAAATGCGTTGATATCATCAGGAACACCGGAGGCGAAGGCGGCTTACTGGGTCCTTTCTGACGCTGAGGAACGAAAGCTAGGGGAGCAnACGGGATTAGATACCCCGGTAGTCCTAnCCGTAAACGATGAGCACTGGACCGGAGCTCTGCACAGGGTTTCGGTCGTAGCGAAAGTGTTAAGTGCTCCGCCTGGGGAGTATGGTCGCAAGGCTGAAACTCAAAGGAATTGACGGGGGCTCACACAAGCGGTGGAGGATGTGGCTTAATTCGAGGCTACGCGAAGAACCTTATCCTAGTCTTGACATGCTTAGGAATCTTCCTGAAAGGGAGGAGTGCTCGCAAGAGAGCCTnTGCACAGGTGCTGCATGGCTGTCGTCAGCTCGTGTCGTGAGATGTCGGGTTAAGTCCCTTAACGAGCGAAACCCTnGTCCTTAGTTACCAGCGCGTCATGGCGGGGACTCTAAGGAGACTGCCGGTGTTAAACCGGAGGAAGGTGGGGATGACGTCAAGTCCTCATGGCCTTTATGATTAGGGCTGCACACGTCCTACAATnGTGCACACAAAGCGACGCAAnCTCGTGAGAGCCAGCTAAGTTCGGATTGCAGGCTGCAACTCGCCTGCATGAAGCTGGAATCGCTAGTAATCGCGGGTCAGCATACCGCGGTGAATGTGTTCCTGAGCCTTGTACACACCGCCCGTCAAGCCACGAAAGTGGGGGGGACCCAACAGCGCTGCCGTAACCGCAAGGAACAAGGCGCCTAAGGTCAACTCCGTGATTGGGACTAAGTCGTAACAAGGTAGCCGTAGGGGAACCTGCGGCTGGATCACCTCCTT',
    );
    my $classification = $cc_broad->classify($seq);
    ok($classification, 'got classification from classifier ' . $classification);
    isa_ok($classification, 'Genome::Utility::MetagenomicClassifier::ChimeraClassification');

    ok ($classification->divergent_genera_count == 0, "no divergent genera");
    ok( $classification->maximum_common_depth == 6, "correct lca");

    my $chimeric_seq = Bio::Seq->new( 
        -display_id => 'chimera', 
        -seq => 'GAGTTTGATTCTGGCTCAGGATGAACGCTAGCTACAGGCTTAACACATGCAAGTCGAGGGGCAGCATGGTCTTAGCTTGCTAAGGCCGATGGCGACCGGCGCACGGGTGAGTAACACGTATCCAACCTGCCGTCTACTCTTGGACAGCCTTCTGAAAGGAAGATTAATACAAGATGGCATCATGAGTCCGCATGTTCACATGATTAAAGGTATTCCGGTAGACGATGGGGATGCGTTCCATTAGATAGTAGGCGGGGTAACGGCCCACCTAGTCTTCGATGGATAGGGGTTCTGAGAGGAAGGTCCCCCACATTGGAACTGAGACACGGTCCAAACTCCTACGGGAGGCAGCAGTGAGGAATATTGGTCAATGGGCGAGAGCCTGAACCAGCCAAGTAGCGTGAAGGATGACTGCCCTATGGGTTGTAAACTTCTTTTATAAAGGAATAAAGTCGGGTATGCATACCCGTTTGCATGTACTTTATGAATAAGGATCGGCTAACTCCGTGCCAGCAGCCGCGGTAATACGGAGGATCCGAGCGTTATCCGGATTTATTGGGTTTAAAGGGAGCGTAGATGGATGTTTAAGTCAGTTGTGAACCGGCGTACTCCCCAGGTGGGATGCTTAACGCTTTCGCTTGGTCACTGACCATAAGGGCCAACAACGAGCATCCATCGTTTACCGCGTGGACTACCAGGGTATCTAATCCTGTTCGATACCCACGCTTTCGAGCATCAGCGTCAGTTGCGCTACAGTAAGCTGCCTTCGCAATCGGAGTTCTTCGTGATATCTAAGCATTTCACCGCTACACCACGAATTCCGCCTACTTTCGGCGCACTCAAGCCCCCCAGTTCGCGCTGCAAGTCGGACGTTGAGCACCCGCATTTCACAACACGCTTAAGAGGCGGCCTACGCTCCCTTTAAACCCAATAAATCCGGATAACGCCTGGACCTTCCGTATTACCGCGGCTGCTGGCACGGAATTAGCCGGTCCTTATTCATGCGGTACCTGCAAAAACCCACACGTGGGCTCTTTTATCCCCGCATAAAAGCAGTTTACAACCCATAGGGCCGTCATCCTGCACGCTACTTGGCTGGTTCAGGCTTACGCCCATTGACCAATATTCCTCACTGCTGCCTCCCGTAGGAGTCTGGACCGTGTCTCAGTTCCAGTGTGGGGGACCTTCCTCTCAGAACCCCTACCGATCGTGGCCACGGTGGGCCGTTACCCCGCCGTCAAGCTAATCGGACGCATCCCCATCCTTTACCGCTAAGCCTTTGGTCCAAATCGGATGCCGTCAATGGACTACATACGGTATTAGTCCGACTTTCGCCGGGTTATCCCGTAGTAAAGGGTAGGTTGGATACGCGTTACTCACCCGTGCGCCGGTCGCCATCAGTAATTGCAAGCAATCActAtGCTGCCCCGCGACTTGCATGTGTTAAGCCTGTAGCtagcgttcatcctgagccagaatcaaactc',
    );

    $classification = $cc_broad->classify($chimeric_seq);
    ok($classification, 'got classification from classifier');
    isa_ok($classification, 'Genome::Utility::MetagenomicClassifier::ChimeraClassification');

    my $divergent_count = $classification->divergent_genera_count;
    ok ($divergent_count > 0, "$divergent_count divergent genera");
    ok( $classification->maximum_common_depth < 6, "correct lca");

#################################################################################################
use Genome::Utility::MetagenomicClassifier::PopulationCompositionFactory;

    my $factory = Genome::Utility::MetagenomicClassifier::PopulationCompositionFactory->instance;
    ok($factory, 'Got factory instance');
    my $composition = $factory->get_composition(
        classifier => Genome::Utility::MetagenomicClassifier::Rdp::Version2x1->new( training_set => 'broad',),
        fasta_file => $ENV{GENOME_TEST_INPUTS} . '/Genome-Utility-MetagenomicClassifier/U_PR-JP_TS1_2PCA.fasta',
    );
    ok($composition, 'Got composition from factory');
    isa_ok($composition, 'Genome::Utility::MetagenomicClassifier::PopulationComposition');

    done_testing();
    