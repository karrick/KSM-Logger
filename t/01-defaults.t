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
# level

sub test_default_level_changable : Tests {
    is(KSM::Logger::level(KSM::Logger::WARNING),
       KSM::Logger::WARNING);
}

########################################
# filename_template

sub test_default_filename_template_changable : Tests {
    is(KSM::Logger::filename_template("/var/log/foo.log"),
       "/var/log/foo.log");
}

########################################
# reformatter

sub test_default_reformatter_changable : Tests {
    my $reformatter = sub {
	my ($line) = @_;
	chomp($line);
	print sprintf("LINE: %s\n", $line);
    };

    my $function = KSM::Logger::reformatter($reformatter);

    my $input = "This is a line of input.";
    
    is(&{$function}($input), &{$reformatter}($input));
}
