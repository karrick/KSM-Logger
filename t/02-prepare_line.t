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
# HELPER

sub simple_reformatter {
    my ($level,$line) = @_;
    my $msgid;
    if($level eq 'DEBUG') {
	$msgid = '1999';
    } elsif($level eq 'VERBOSE') {
	$msgid = '2499';
    } elsif($level eq 'INFO') {
	$msgid = '2999';
    } elsif($level eq 'WARNING') {
	$msgid = '5999';
    } elsif($level eq 'ERROR') {
	$msgid = '8999';
    } else {
	$msgid = '9999';
    }
    sprintf("(%s) %s: %s", $msgid, $level, $line);
}

########################################

sub test_prepare_line_invokes_sprintf : Tests {
    like(KSM::Logger::prepare_line("INFO", "Is %s called?", "sprintf"),
	 qr/^INFO: \(pid \d+\) Is sprintf called\?/);
}

sub test_prepare_line_invokes_reformatter : Tests {
    KSM::Logger::reformatter(\&simple_reformatter);

    is(KSM::Logger::prepare_line("DEBUG", "Now is the time"),
       "(1999) DEBUG: Now is the time\n");
    is(KSM::Logger::prepare_line("VERBOSE", "for all good men"),
       "(2499) VERBOSE: for all good men\n");
    is(KSM::Logger::prepare_line("INFO", "to come to the"),
       "(2999) INFO: to come to the\n");
    is(KSM::Logger::prepare_line("WARNING", "of their"),
       "(5999) WARNING: of their\n");
    is(KSM::Logger::prepare_line("ERROR", "country"),
       "(8999) ERROR: country\n");
}
