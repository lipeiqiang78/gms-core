#!/usr/bin/perl

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use Test::Deep;
use Test::Exception;
use File::Spec;

my $pkg = "Genome::Annotation::Plan";
use_ok($pkg) || die;

my $plan_file = File::Spec->join(__FILE__ . ".d", "test.yaml");

my $plan = $pkg->create_from_file($plan_file);
ok($plan, "Made a plan from file ($plan_file).");

my $expected_hashref = {
    experts   => {
        expert_one => {
            e1_p1 => 'something',
            e1_p2 => 'something else'
        },
        expert_two => {
            e2_p1 => 'something',
            e2_p2 => 'something else'
        }
    },
    reporters => {
        reporter_alpha => {
            filters      => {
                filter_a => {
                    fa_p1 => 'something',
                    fa_p2 => 'something else'
                },
                filter_b => {
                    fb_p1 => 'something',
                    fb_p2 => 'something else'
                }
            },
            interpreters => {
                interpreter_x => {
                    ix_p1 => 'something',
                    ix_p2 => 'something else'
                },
                interpreter_y => {
                    iy_p1 => 'something',
                    iy_p2 => 'something else'
                }
            },
            params       => {
                ra_p1 => 'something',
                ra_p2 => 'something else'
            }
        },
        reporter_beta  => {
            filters => {},
            interpreters => { interpreter_x => {
                    ix_p1 => 'something',
                    ix_p2 => 'something else'
                } },
            params       => {
                rb_p1 => 'something',
                rb_p2 => 'something else'
            }
        }
    }
};

is_deeply($plan->as_hashref, $expected_hashref, "Got expected hashref from 'as_hashref'.");
is_deeply($pkg->create_from_hashref($plan->as_hashref)->as_hashref, $plan->as_hashref, "Roundtrip hashref test successful.");
is_deeply($pkg->create_from_json($plan->as_json)->as_hashref, $expected_hashref, "Roundtrip JSON test successful.");

my $path = Genome::Sys->create_temp_file_path;
$plan->write_to_file($path);
is_deeply($pkg->create_from_file($path)->as_hashref, $expected_hashref, "Roundtrip yaml file test successful.");

my $expert_one_plan = $plan->get_plan('expert', 'expert_one');
is($expert_one_plan->name, 'expert_one', "Got correct plan ('expert_one') from get_plan");

my $reporter_alpha_plan = $plan->get_plan('reporter', 'reporter_alpha');
is($reporter_alpha_plan->name, 'reporter_alpha', "Got correct plan ('reporter_alpha') from get_plan");

throws_ok sub {$plan->get_plan('bad_category', 'bad_name');}, qr(bad_category), "Dies when given a bad category";
throws_ok sub {$plan->get_plan('expert', 'bad_name');}, qr(bad_name), "Dies when given a bad name";

done_testing();
