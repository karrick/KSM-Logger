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

sub test_logit_returns_finished_line : Tests {
    my ($stdout,$stderr,@result) = capture {
	like(info("Hello, %s!", "World"), qr|^Hello, World!$|);
    };
}
