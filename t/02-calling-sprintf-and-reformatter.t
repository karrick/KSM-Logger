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

use Capture::Tiny qw(capture);
use KSM::Logger qw(:all);

########################################

sub setup_logs : Tests(setup) {
}

########################################
# TEST HELPERS

sub with_temp {
    my ($function) = @_;
    if(ref($function) ne 'CODE') {
    	croak("first argument to with_temp ought to be a function");
    }
    chomp(my $temp = `mktemp`);
    my $result = eval {&{$function}($temp)};
    my $status = $@;
    unlink($temp) if -e $temp;
    if($status) {croak $status}
    $result;
}

########################################

sub file_contents {
    my ($filename) = @_;
    local $/;
    open(FH, '<', $filename) 
	or croak sprintf("unable to open file %s: %s",
			 $filename, $!);
    <FH>;
}

########################################

sub with_captured_log {
    my $function = shift;
    # remaining args for function

    with_temp(
	sub {
	    my $logfile = shift;
	    # remaining args for function
	    KSM::Logger::initialize({level => KSM::Logger::DEBUG,
				     filename_template => $logfile,
				     reformatter => \&simple_reformatter});
	    eval { &{$function}(@_) };
	    file_contents($logfile);
	});
}

########################################
# TEST FIXTURE FUNCTION

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
    my $log = with_captured_log(
	sub {
	    my ($stdout,$stderr,@result) = capture {
		is(debug("Is %s called?", "sprintf"),
		   "Is sprintf called?",
		   "should return string returned by sprintf w/o calling REFORMATTER");
	    };
	});
    like($log, qr/\(1999\) DEBUG: Is sprintf called\?/);
}

sub test_prepare_line_invokes_reformatter : Tests {

    my $log = with_captured_log(
	sub {
	    my ($stdout,$stderr,@result) = capture {
		debug("Now is the time");
		verbose("for all good men");
		info("to come to the");
		warning("aid of");
		error("their country");
	    };
	});
    like($log, qr/\(1999\) DEBUG: Now is the time/);
    like($log, qr/\(2499\) VERBOSE: for all good men/);
    like($log, qr/\(2999\) INFO: to come to the/);
    like($log, qr/\(5999\) WARNING: aid of/);
    like($log, qr/\(8999\) ERROR: their country/);
}
