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

sub file_contents {
    my ($filename) = @_;
    local $/;
    open(FH, '<', $filename)
	or croak sprintf("unable to open file %s: %s", $filename, $!);
    <FH>;
}

########################################

sub setup_logging : Tests(startup) {
    KSM::Logger::initialize();
}

sub create_temp_file : Tests(setup) {
    my ($self) = @_;
    ($self->{fh},$self->{fname}) = File::Temp::tempfile(); 
}

sub remove_temp_file : Tests(teardown) {
    my ($self) = @_;
    unlink($self->{fname});
}

########################################

sub test_logs_to_stderr_when_undef_filename_template : Tests {
    my ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template(undef);
	info("line 1 to standard error");
    };
    like($stderr, qr|line 1 to standard error|);
    is($stdout, "");
}

sub test_logs_to_stderr_when_empty_filename_template : Tests {
    my ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template('');
	info("line 1 to standard error");
    };
    like($stderr, qr|line 1 to standard error|);
    is($stdout, "");
}

sub test_logs_to_filename_if_given : Tests {
    my ($self) = @_;
    my ($stdout,$stderr,@result);

    ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template($self->{fname});	
	info("line 3 to stderr and temp log file");
    };
    like(file_contents($self->{fname}),
	 qr|\[\d{4}-\d\d-\d\d \d\d:\d\d:\d\d .*\] \d+ INFO: \(pid \d+\) line 3 to stderr and temp log file|);
}

sub test_can_change_logs_back_and_forth : Tests {
    my ($self) = @_;
    my ($stdout,$stderr,@result);

    # THIS DISABLED: It seems that capture for testing and duping
    # STDOUT is not working together quite as seemlessly as I had
    # hoped.

    # ($stdout,$stderr,@result) = capture {
    # 	KSM::Logger::filename_template(undef);
    # 	info("line 1 to stderr");
    # };
    # like($stderr, qr|line 1 to stderr|);

    ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template($self->{fname});
	info("line 2 to stderr and log file");
    };
    like($stderr, qr|line 2 to stderr and log file|);
    like(file_contents($self->{fname}), qr|INFO: \(pid \d+\) line 2 to stderr and log file|);

    ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template(undef);
	info("line 3 to stderr only");
    };
    like($stderr, qr|line 3 to stderr only|);
    unlike(file_contents($self->{fname}), qr|INFO: \(pid \d+\) line 3 to stderr only|);
    
    ($stdout,$stderr,@result) = capture {
	KSM::Logger::filename_template($self->{fname});
	info("line 4 to stderr and log file");
    };
    like($stderr, qr|line 4 to stderr and log file|);
    like(file_contents($self->{fname}), qr|INFO: \(pid \d+\) line 4 to stderr and log file|);
}
