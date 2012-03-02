#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use File::Basename;

use Test::More;
use Test::Class;
use base qw(Test::Class);
END { Test::Class->runtests }

########################################

use KSM::Logger qw(:all);

########################################

sub initialize_logger : Tests(setup) {
    KSM::Logger::initialize();
}

########################################
# initialize

sub test_initialize_uses_sensible_defaults : Tests {
    is(KSM::Logger::filename_template(), 
       sprintf("/tmp/%s.%%F.log", File::Basename::basename($0)));
    is(KSM::Logger::level(), KSM::Logger::INFO);
}
