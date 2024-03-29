package Genome::Annotation::Plan::ReporterPlan;

use strict;
use warnings FATAL => 'all';
use Genome;
use Set::Scalar;

class Genome::Annotation::Plan::ReporterPlan {
    is => 'Genome::Annotation::Plan::Base',
    has => [
        interpreter_plans => {
            is => 'Genome::Annotation::InterpreterPlan',
            is_many => 1,
        },
        filter_plans => {
            is => 'Genome::Annotation::FilterPlan',
            is_many => 1,
            is_optional => 1,
        },
    ],
};

sub category {
    'reporters';
}

sub children {
    my $self = shift;
    return ('interpreters' => [$self->interpreter_plans],
        'filters' => [$self->filter_plans]);
}

sub create_from_hashref {
    my $class = shift;
    my $name = shift;
    my $hashref = shift;

    my $self = $class->SUPER::create(
        name => $name,
        params => $hashref->{params},
    );

    my @filter_plans;
    for my $filter_name (keys %{$hashref->{filters}}) {
        push @filter_plans, Genome::Annotation::Plan::FilterPlan->create(
            name => $filter_name,
            params => $hashref->{filters}->{$filter_name},
        );
    }
    $self->filter_plans(\@filter_plans);

    my @interpreter_plans;
    for my $interpreter_name (keys %{$hashref->{interpreters}}) {
        push @interpreter_plans, Genome::Annotation::Plan::InterpreterPlan->create(
            name => $interpreter_name,
            params => $hashref->{interpreters}->{$interpreter_name},
        );
    }
    $self->interpreter_plans(\@interpreter_plans);

    return $self;
}

sub validate_self {
    my $self = shift;
    $self->SUPER::validate_self(@_);

    my $needed = Set::Scalar->new($self->object->requires_interpreters);
    my $have = Set::Scalar->new(map {$_->name} $self->interpreter_plans);
    unless($needed->is_equal($have)) {
        if (my $still_needed = $needed - $have) {
            $self->error_message("Interpreters required by reporter (%s) but not provided: (%s)",
                $self->name, join(",", $still_needed->members));
        }
        if (my $not_needed = $have - $needed) {
            $self->error_message("Interpreters provided by plan but not required by reporter (%s): (%s)",
                $self->name, join(",", $not_needed->members));
        }
        die $self->error_message("Provided interpreters and required interpreters do not match");
    }
}

1;
