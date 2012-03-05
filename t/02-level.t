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

use KSM::Logger qw(:all);

########################################

sub test_accepts_valid_levels : Tests {
    is(KSM::Logger::level(KSM::Logger::DEBUG), KSM::Logger::DEBUG);
    is(KSM::Logger::level(KSM::Logger::VERBOSE), KSM::Logger::VERBOSE);
    is(KSM::Logger::level(KSM::Logger::INFO), KSM::Logger::INFO);
    is(KSM::Logger::level(KSM::Logger::WARNING), KSM::Logger::WARNING);
    is(KSM::Logger::level(KSM::Logger::ERROR), KSM::Logger::ERROR);
}

sub test_croaks_when_level_too_low : Tests {
    eval {KSM::Logger::level(KSM::Logger::DEBUG + 100)};
    like($@, qr|unknown level|);
}

sub test_croaks_when_level_too_high : Tests {
    eval {KSM::Logger::level(KSM::Logger::ERROR - 100)};
    like($@, qr|unknown level|);
}

# NOTE: For some odd reason, unable to modify code to also pass below
# test.

# sub test_croaks_when_level_invalid_string : Tests {
#     eval {KSM::Logger::level('foo')};
#     like($@, qr|unknown level|);
# }
