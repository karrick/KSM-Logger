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
# initialize

sub test_initialize_accepts_custom_options : Tests {
    KSM::Logger::initialize({filename_template => "log/foobarbaz/foo.%F.log",
			     level => KSM::Logger::WARNING});
    is(KSM::Logger::filename_template(), "log/foobarbaz/foo.%F.log");
    is(KSM::Logger::level(), KSM::Logger::WARNING);
}

sub test_dies_when_unable_to_open_log_file : Tests {
    eval {
	KSM::Logger::initialize({filename_template => "/var/log/foo.log"});
	info("must log something to force open of log file");
    };
    like($@, qr/^unable to open log for writting/);
}
