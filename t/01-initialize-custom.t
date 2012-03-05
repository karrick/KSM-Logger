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

use File::Temp ();
use KSM::Logger qw(:all);

########################################

sub create_temp_file : Tests(setup) {
    my ($self) = @_;
    ($self->{fh},$self->{fname}) = File::Temp::tempfile(); 
}

sub remove_temp_file : Tests(teardown) {
    my ($self) = @_;
    unlink($self->{fname});
}

########################################
# initialize

sub test_initialize_accepts_custom_options : Tests {
    my ($self) = @_;
    KSM::Logger::initialize({filename_template => $self->{fname},
			     level => KSM::Logger::VERBOSE});
    info("must output something to force opening of log file");
    is($KSM::Logger::FILENAME_OPENED, $self->{fname});
    is($KSM::Logger::LEVEL, KSM::Logger::VERBOSE);
}
