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

sub test_dies_when_unable_to_open_log_file : Tests {
    my ($stdout,$stderr,@result) = capture {
	eval {
	    KSM::Logger::initialize({filename_template => "/root/log/foo.log"});
	    info("attempting to log something will attempt to open log file");
	};
	like($@, qr|^unable to create new log file .* Permission denied|);
    };
    is($stderr, '');
}
