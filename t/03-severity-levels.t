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

sub test_debug_level_shows_all : Tests {
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::DEBUG);
    KSM::Logger::reformatter($mock_reformatter);

    debug("debug debug");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    verbose("debug verbose");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    info("debug info");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    warning("debug warning");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    error("debug error");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;
}

sub test_verbose_level_hides_debug : Tests {
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::VERBOSE);
    KSM::Logger::reformatter($mock_reformatter);

    debug("verbose debug hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    verbose("verbose verbose");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    info("verbose info");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    warning("verbose warning");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    error("verbose error");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;
}

sub test_info_level_hides_debug_and_verbose : Tests {
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::reformatter($mock_reformatter);

    debug("info debug hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    verbose("info verbose hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    info("info info");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    warning("info warning");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    error("info error");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;
}

sub test_warning_level_hides_debug_info_and_info : Tests {
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::WARNING);
    KSM::Logger::reformatter($mock_reformatter);

    debug("warning debug hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    verbose("warning verbose hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    info("warning info hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    warning("warning warning");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;

    error("warning error");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;
}

sub test_error_level_hides_all_but_error : Tests {
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::ERROR);
    KSM::Logger::reformatter($mock_reformatter);

    debug("error debug hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    verbose("error verbose hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    info("error info hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    warning("error warning hidden");
    ok(!$reformatter_invoked);
    $reformatter_invoked = 0;

    error("error error");
    ok($reformatter_invoked);
    $reformatter_invoked = 0;
}
