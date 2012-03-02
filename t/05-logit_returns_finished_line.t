#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use Test::More;
use Test::Class;
use base qw(Test::Class);
END { Test::Class->runtests }

########################################

use KSM::Logger qw(:all);

########################################

sub save_defaults : Tests(setup) {
    my ($self) = @_;
    $self->{filename_template} = KSM::Logger::filename_template();
    $self->{level} = KSM::Logger::level();
    $self->{reformatter} = KSM::Logger::reformatter();
}

sub restore_reformatter : Tests(teardown) {
    my ($self) = @_;
    KSM::Logger::filename_template($self->{filename_template});
    KSM::Logger::level($self->{level});
    KSM::Logger::reformatter($self->{reformatter});
}

########################################

sub test_logit_returns_finished_line : Tests {
    like(info("Hello, World!"), qr/^Hello, World!$/);
}

