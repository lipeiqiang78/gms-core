#!/usr/bin/env genome-perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use above 'Genome';
use Genome::Utility::Test qw(compare_ok);

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

my $pkg = 'Genome::Model::Build::HasFeatureLists';
use_ok($pkg) || die;

{
package Genome::Model::Build::TestHasFeatureLists;

use strict;
use warnings FATAL => 'all';
use Genome;

class Genome::Model::Build::TestHasFeatureLists {
    is => [
        'Genome::Model::Build::HasFeatureLists',
    ],
    has => [
        get_target_region_file_list => {
        },
    ],
};

1;
}

my $target = Genome::Model::Build::TestHasFeatureLists->__define__();
throws_ok( sub {$target->get_feature_list('bad_name')} , qr(No accessor for name));
throws_ok( sub {$target->get_feature_list('segmental_duplications')} , qr(is not defined));
throws_ok( sub {$target->get_feature_list('target_region')} , qr(Couldn't get feature_list));

my $feature_list = Genome::FeatureList->__define__();
$target->get_target_region_file_list($feature_list);
is($target->get_feature_list('target_region'), $feature_list, 'Got expected feature list');

done_testing();
