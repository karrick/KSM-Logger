#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Carp;

use Test::More;
use Test::Class;
use base qw(Test::Class);
END { Test::Class->runtests }

########################################

use KSM::Logger qw(:all);

########################################

sub initialize_logger : Tests(startup) {
    info("must log something to setup signal handlers (TODO?)");
}

sub save_defaults : Tests(setup) {
    my ($self) = @_;
    $self->{__DIE__} = $SIG{__DIE__};
    $self->{__WARN__} = $SIG{__WARN__};
    $self->{filename_template} = KSM::Logger::filename_template();
    $self->{level} = KSM::Logger::level();
    $self->{reformatter} = KSM::Logger::reformatter();
    $self->{reformatter_invoked} = 0;

    KSM::Logger::reformatter(sub {
	my ($level,$line) = @_;
	$self->{reformatter_invoked} = 1;
	sprintf("%s: %s", $level, $line);
			     });
}

sub restore_reformatter : Tests(teardown) {
    my ($self) = @_;
    $SIG{__DIE__} = $self->{__DIE__};
    $SIG{__WARN__} = $self->{__WARN__};
    KSM::Logger::filename_template($self->{filename_template});
    KSM::Logger::level($self->{level});
    KSM::Logger::reformatter($self->{reformatter});
}

########################################

sub test_catches_warn_pseudo_signal : Tests {
    my ($self) = @_;
    warn("invoking warn");
    ok($self->{reformatter_invoked});
}

sub test_catches_die_pseudo_signal : Tests {
    my ($self) = @_;
    eval {die("invoking die");};
    like($@, qr/^invoking\b/);
    # NOTE: if we don't catch the die signal, then the test will
    # fail, so we cannot cause a die that will log.

    # ok($self->{reformatter_invoked});
}
