#!/usr/bin/env perl

use utf8;
use diagnostics;
use strict;
use warnings;
use Carp;
use Test::More;
use Test::Class;
use base qw(Test::Class);
END { Test::Class->runtests }

########################################

use Capture::Tiny qw(capture);
use File::Temp;
use KSM::Logger qw(:all);

########################################

sub setup_logging : Tests(setup) {
    my ($self) = @_;
    
    ($self->{fh},$self->{fname}) = File::Temp::tempfile(); 
    KSM::Logger::initialize({
	filename_template => $self->{fname},
	level => KSM::Logger::INFO});
}

sub remove_temp_file : Tests(teardown) {
    my ($self) = @_;
    unlink($self->{fname});
}

########################################

sub file_contents {
    my ($filename) = @_;
    local $/;
    open(FH, '<', $filename) or croak("unable to open file [$filename]: $!");
    <FH>;
}

########################################

sub test_debug_level_shows_all : Tests {
    my ($self) = @_;
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::DEBUG);
    KSM::Logger::reformatter($mock_reformatter);

    my ($stdout,$stderr,@result) = capture {
	debug("call debug when level debug");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	verbose("call verbose when level debug");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	info("call info when level debug");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	warning("call warning when level debug");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	error("call error when level debug");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	my $contents = file_contents($self->{fname});
	like($contents, qr|DEBUG|);
	like($contents, qr|VERBOSE|);
	like($contents, qr|INFO|);
	like($contents, qr|WARNING|);
	like($contents, qr|ERROR|);
    };
}

sub test_verbose_level_hides_debug : Tests {
    my ($self) = @_;
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::VERBOSE);
    KSM::Logger::reformatter($mock_reformatter);

    my ($stdout,$stderr,@result) = capture {
	debug("debug called when level verbose hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	verbose("verbose called when level verbose");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	info("info called when level verbose");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	warning("warning called when level verbose");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	error("error called when level verbose");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	my $contents = file_contents($self->{fname});
	unlike($contents, qr|hidden|);
	like($contents, qr|VERBOSE|);
	like($contents, qr|INFO|);
	like($contents, qr|WARNING|);
	like($contents, qr|ERROR|);
    };
}

sub test_info_level_hides_debug_and_verbose : Tests {
    my ($self) = @_;
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::reformatter($mock_reformatter);

    my ($stdout,$stderr,@result) = capture {
	debug("debug called when level info hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	verbose("verbose called when level info hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	info("info called when level info");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	warning("warning called when level info");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	error("error called when level info");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	my $contents = file_contents($self->{fname});
	unlike($contents, qr|hidden|);
	like($contents, qr|INFO|);
	like($contents, qr|WARNING|);
	like($contents, qr|ERROR|);
    };
}

sub test_warning_level_hides_debug_info_and_info : Tests {
    my ($self) = @_;
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::WARNING);
    KSM::Logger::reformatter($mock_reformatter);

    my ($stdout,$stderr,@result) = capture {
	debug("debug called when level warning hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	verbose("verbose called when level warning hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	info("info called when level warning hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	warning("warning called when level warning");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	error("error called when level warning");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	my $contents = file_contents($self->{fname});
	unlike($contents, qr|hidden|);
	like($contents, qr|WARNING|);
	like($contents, qr|ERROR|);
    };
}

sub test_error_level_hides_all_but_error : Tests {
    my ($self) = @_;
    my $reformatter_invoked;
    my $mock_reformatter = sub {
	my ($level,$line) = @_;
	$reformatter_invoked = 1;
	sprintf("%s: %s", $level, $line);
    };
    KSM::Logger::level(KSM::Logger::ERROR);
    KSM::Logger::reformatter($mock_reformatter);

    my ($stdout,$stderr,@result) = capture {
	debug("debug called when level error hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	verbose("verbose called when level error hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	info("info called when level error hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	warning("warning called when level error hidden");
	ok(!$reformatter_invoked);
	$reformatter_invoked = 0;

	error("error called when level error");
	ok($reformatter_invoked);
	$reformatter_invoked = 0;

	my $contents = file_contents($self->{fname});
	unlike($contents, qr|hidden|);
	like($contents, qr|ERROR|);
    };
}
