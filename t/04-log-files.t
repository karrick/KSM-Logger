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

sub test_log_filename_formats_argument_with_strftime : Tests {
    like(KSM::Logger::log_filename(KSM::Logger::filename_template()),
	 qr/^\/tmp\/t\/04\-log\-files\.t\.\d{4}\-\d\d\-\d\d\.log$/);
}
