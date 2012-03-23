package KSM::Logger;

use utf8;
use strict;
use warnings;

use Carp;
use File::Basename ();
use File::Path ();
use POSIX ();

use constant ERROR => 0;
use constant WARNING => ERROR + 1;
use constant INFO => WARNING + 1;
use constant VERBOSE => INFO + 1;
use constant DEBUG => VERBOSE + 1;

=head1 NAME

KSM::Logger - The great new KSM::Logger!

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

KSM::Logger provides an abstracted view of your program's logging
needs.  It has multiple logging levels, automatically rolls logs based
on a filename template you provide, and can optionally invoke a
reformatter function you provide for each log event.

  Quick summary of what the module does.

Perhaps a little code snippet.

    use KSM::Logger qw(:all);

    KSM::Logger::initialize({filename_template => "/var/log/my_program/foo.%F.log",
                             level => KSM::Logger::VERBOSE,
                             reformatter => sub {
                               my ($level,$line) = @_;
                               sprintf("%s: (pid %d) %s", $level, $$, $line);
                            }});

    ...

    info("Initializing Foo");
    eval {
        debug("config file: %s", $config_file);
        if(! -r $config_file) {
            # NOTE: logging functions return finished log line,
            # so you can pass them on to die, warn, carp, and croak:
            croak error("config file not found: %s",
                        $config_file);
        }
        ...
    };


=head1 EXPORT

Although nothing is exported by default, the most common functions may
be included by importing the :all tag.  For example:

    use KSM::Logger qw(:all);

=cut

use Exporter qw(import);
our %EXPORT_TAGS = ( 'all' => [qw(
	debug
	verbose
	info
	warning
	error
)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

=head2 GLOBALS

Some module level global variables are required to manage log state.

=cut

our $FILENAME_OPENED;
our $FILENAME_TEMPLATE;
our $LEVEL = INFO;
our $LOG_FILEHANDLE;
our $REFORMATTER = \&REFORMATTER;

=head1 SUBROUTINES/METHODS

=head2 initialize

Initializes logging for your application by setting the filename
template, log level, and the log event reformatter function.

You may set or ignore any or all of the options.  Reasonable defaults
are chosen for the parameters you choose to ignore.

=cut

sub initialize {
    my ($options) = @_;
    if(defined($options)) {
	if(ref($options) eq 'HASH') {
	    if(defined($options->{filename_template})) {
		filename_template($options->{filename_template});
	    }
	    if(defined($options->{level})) {
		level($options->{level});
	    }
	    if(defined($options->{reformatter})) {
		reformatter($options->{reformatter});
	    }
	} else {
	    croak("ought to pass in either option hash, or nothing\n");
	}
    }
}

=head2 REFORMATTER

Default log event reformatter.  Prefix the log event with timestamp,
the severity level string, and the process PID.

=cut

sub REFORMATTER {
    my ($level,$line) = @_;
    sprintf("%s %s: (pid %d) %s",
 	    POSIX::strftime("[%F %T %Z] %s", gmtime),
	    $level, $$, $line);
}

=head2 level

Controls the log level.  With an argument, sets the log level.  Always
returns the log level.

=cut

sub level {
    if(scalar(@_)) {
	my ($value) = @_;
	no warnings 'numeric';
	if($value >= ERROR && $value <= DEBUG) {
	    $LEVEL = $value;
	} else {
	    croak sprintf("unknown level: [%s]\n", $value);
	}
    }
    $LEVEL;
}

=head2 filename_template

Use the &filename_template function to change the format of the
filename, including its path.

KSM::Logger will attempt to create the required directories on the
path when opening a log file.

The template will be passed through &strftime, so you can include
codes from strftime(3), as the default value shows below, to partition
your logs based on time.  You can place strftime codes in both the
path and filename portion of the template.

If not explicitly set, the filename template will be set to
"/tmp/$0.%F.log", where $0 is the basename of your program.

Note that when Logger needs to roll logs, it will use the same
template that you gave it before.  If your program is daemonized, its
directory may be somewhere else than where you started it.  For this
reason, you should always give Logger an absolute path for the log
file template.

=cut

sub filename_template {
    if(scalar(@_)) {
	$FILENAME_TEMPLATE = shift;
    }
    $FILENAME_TEMPLATE;
}

=head2 reformatter

With an argument, sets the log reformatter.  Always returns the log
reformatter.

For each log event, the reformatter is invoked with two arguments, the
first is the log level, e.g, 'DEBUG', and the second is the sprintf
formatted line.

=cut

sub reformatter {
    if(scalar(@_)) {
	my $value = shift;
	croak("ought to be function\n") if(ref($value) ne 'CODE');
	$REFORMATTER = $value;
    }
    $REFORMATTER;
}

=head2 debug

Outputs a log event if the log level is DEBUG.

Always returns the log event as formatted by sprintf, but not the
REFORMATTER function.

=cut

sub debug {
    my $template = shift;
    my $line = eval {sprintf($template, @_)};
    croak($@) if($@);
    ($LEVEL == DEBUG ? logit('DEBUG', $line) : $line);
}

=head2 verbose

Outputs a log event if the log level is VERBOSE or above.

Always returns the log event as formatted by sprintf, but not the
REFORMATTER function.

=cut

sub verbose {
    my $template = shift;
    my $line = eval {sprintf($template, @_)};
    croak($@) if($@);
    ($LEVEL >= VERBOSE ? logit('VERBOSE', $line) : $line);
}

=head2 info

Outputs a log event if the log level is INFO or above.

Always returns the log event as formatted by sprintf, but not the
REFORMATTER function.

=cut

sub info {
    my $template = shift;
    my $line = eval {sprintf($template, @_)};
    croak($@) if($@);
    ($LEVEL >= INFO ? logit('INFO', $line) : $line);
}

=head2 warning

Outputs a log event if the log level is WARNING or above.

Always returns the log event as formatted by sprintf, but not the
REFORMATTER function.

=cut

sub warning {
    my $template = shift;
    my $line = eval {sprintf($template, @_)};
    croak($@) if($@);
    ($LEVEL >= WARNING ? logit('WARNING', $line) : $line);
}

=head2 error

Outputs a log event regardless of the log level.

Always returns the log event as formatted by sprintf, but not the
REFORMATTER function.

=cut

sub error {
    my $template = shift;
    my $line = eval {sprintf($template, @_)};
    croak($@) if($@);
    logit('ERROR', $line);
}

=head2 logit

Internal function that invokes the user's reformatter with the log
event, then writes the log to the correct file.

It trims all whitespace from both ends of the string returned by the
REFORMATTER function.

If there are date or time codes from strftime(3) in the filename
template, it will close and re-open new logs when necessary.

=cut

sub logit {
    my ($level,$line) = @_;
    my $reformatted = &{$REFORMATTER}($level,$line);
    $reformatted =~ s/^\s+//g;
    $reformatted =~ s/\s+$//g;
    my $fh = log_filehandle();
    printf $fh "%s\n", $reformatted;
    $line;
}

=head2 log_filehandle

Internal function that ensures the correct log file is used.

If this cannot open a log file and it doesn't already have an open
file handle, it will die with nowhere to write logs.  If there is an
open file handle, it will warn the user and continue using the
existing log file.

=cut

sub log_filehandle {
    if(defined($FILENAME_TEMPLATE) && $FILENAME_TEMPLATE ne '') {
	change_log_to_file();
    } else {
	change_log_to_standard_error();
    }
}

=head2 change_log_to_standard_error

Internal function called when filename_template is undefined or the
empty string.

=cut

sub change_log_to_standard_error {
    open($LOG_FILEHANDLE,'>&STDERR') or die sprintf("Cannot dup stderr: %s\n", $!);
    undef $FILENAME_OPENED;
    $LOG_FILEHANDLE;
}

=head2 change_log_to_file

Internal function called when filename_template is a valid string.

=cut

sub change_log_to_file {
    my $want_file = POSIX::strftime($FILENAME_TEMPLATE, gmtime);
    if(!defined($FILENAME_OPENED) || $want_file ne $FILENAME_OPENED) {
	eval {
	    File::Path::mkpath(File::Basename::dirname($want_file));
	    open(my $fh, '>>', $want_file)
		or die sprintf("unable to append [%s]: %s\n", $want_file, $!);
	    if(defined($LOG_FILEHANDLE)) {
		printf $LOG_FILEHANDLE "INFO: logs continued [$want_file]\n";
		close $LOG_FILEHANDLE;
	    }
	    $LOG_FILEHANDLE = $fh;
	    select((select($LOG_FILEHANDLE), $| = 1)[0]); # autoflush
	    $FILENAME_OPENED = $want_file;
	};
	if($@) {
	    if(defined($LOG_FILEHANDLE)) {
		printf $LOG_FILEHANDLE "WARNING: unable to create new log file [%s]: %s\n", $want_file, $@;
	    } else {
		# FIXME: nowhere to write logs (hours of trouble-shooting if daemonized...)
		die sprintf("nowhere to write logs: %s\n", $@);
	    }
	}		
    }
    $LOG_FILEHANDLE;
}

=head1 AUTHOR

Karrick S. McDermott, C<< <karrick at karrick.net> >>

=head1 TODO

* Better error checking on options to &level and &filename_template
  functions.


=head1 BUGS

Please report any bugs or feature requests to C<bug-ksm-logger at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KSM-Logger>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc KSM::Logger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=KSM-Logger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/KSM-Logger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/KSM-Logger>

=item * Search CPAN

L<http://search.cpan.org/dist/KSM-Logger/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Karrick S. McDermott.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of KSM::Logger
