package KSM::Logger;

use warnings;
use strict;
use Carp;
use File::Basename;
use File::Path;
use POSIX;

use constant ERROR => 0;
use constant WARNING => ERROR + 1;
use constant INFO => WARNING + 1;
use constant VERBOSE => INFO + 1;
use constant DEBUG => VERBOSE + 1;

=head1 NAME

KSM::Logger - The great new KSM::Logger!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

our $FILENAME_OPENED;
our $FILENAME_TEMPLATE = sprintf("/tmp/%s.%%F.log", $0);
our $LEVEL = INFO;
our $LOG_FILEHANDLE;
our $REFORMATTER = \&REFORMATTER;

=head1 SYNOPSIS

KSM::Logger provides an abstracted view of your program's logging
needs.  It has multiple logging levels, automatically rolls logs based
on a filename template you provide, and can optionally invoke a
reformatter function you provide for each log event.

  Quick summary of what the module does.

Perhaps a little code snippet.

    use KSM::Logger qw(debug verbose info warning error);

    KSM::Logger::initialize({subsystem => 'my_subsystem',
                             filename_template => "/var/log/my_program/foo.%F.log",
                             level => KSM::Logger::VERBOSE});
    KSM::Logger::reformatter(sub {
	my ($level,$line) = @_;
        sprintf("%s: (pid %d) %s", $level, $$, $line);
    });

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

=head1 SUBROUTINES/METHODS

=head2 initialize

Initializes logging for your application by setting the subsystem and
the log filename template.  It also configures the logger to use the
e3 common log format.

=cut

sub initialize {
    my ($options) = @_;
    if(defined($options->{filename_template})) {
	KSM::Logger::filename_template($options->{filename_template});
    }
    if(defined($options->{level})) {
	KSM::Logger::level($options->{level});
    }
    if(defined($options->{reformatter})) {
	KSM::Logger::reformatter($options->{reformatter});
    }
}

=head2 REFORMATTER

Default line reformatter.  Prefix the log event with timestamp, the
severity level string, and the process PID.

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
	$LEVEL = shift;
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
"/tmp/$0.%F.log".

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
	$REFORMATTER = shift;
    }
    $REFORMATTER;
}

=head2 prepare_line

Prepare a single log event for output by invoking sprintf on the
remaining arguments, and then invoking the optionally user-supplied
reformatter on the result from sprintf formatting.

=cut

sub prepare_line {
    my $level = shift;
    my $template = shift;
    # NOTE: remaining args are for sprintf
    chomp(my $line = &{$REFORMATTER}($level, sprintf($template, @_)));
    sprintf("%s\n", $line);
}

=head2 debug

Outputs a log event if the log level is DEBUG.

=cut

sub debug {
    if($LEVEL == DEBUG) {
	unshift(@_, 'DEBUG');
	logit(prepare_line(@_));
    }
}

=head2 verbose

Outputs a log event if the log level is VERBOSE or above.

=cut

sub verbose {
    if($LEVEL >= VERBOSE) {
	unshift(@_, 'VERBOSE');
	logit(prepare_line(@_));
    }
}

=head2 info

Outputs a log event if the log level is INFO or above.

=cut

sub info {
    if($LEVEL >= INFO) {
	unshift(@_, 'INFO');
	logit(prepare_line(@_));
    }
}

=head2 warning

Outputs a log event if the log level is WARNING or above.

=cut

sub warning {
    if($LEVEL >= WARNING) {
	unshift(@_, 'WARNING');
	logit(prepare_line(@_));
    }
}

=head2 error

Outputs a log event regardless of the log level.

=cut

sub error {
    unshift(@_, 'ERROR');
    logit(prepare_line(@_));
}

=head2 log_filename

Internal function that determines what the current log file should be
used based on the date and time.

=cut

sub log_filename {
    POSIX::strftime(shift, gmtime);
}

=head2 log_filehandle

Internal function that ensures the correct log file is used.

If this cannot open a log file and it doesn't already have an open
file handle, it will die with nowhere to write logs.  If there is an
open file handle, it will warn the user and continue using the
existing log file.

=cut

sub log_filehandle {
    my ($template) = @_;
    my $need_file = log_filename($template);
    if(!defined($FILENAME_OPENED) || $need_file ne $FILENAME_OPENED) {
	local $SIG{__DIE__} = 'DEFAULT';
	eval {
	    File::Path::mkpath(File::Basename::dirname($need_file));
	    open(my $fh, '>>', $need_file)
		or die sprintf("unable to append [%s]: %s", $need_file, $!);
	    if(defined($LOG_FILEHANDLE)) {
		print $LOG_FILEHANDLE prepare_line('INFO', "Logs continued [%s]",
						   File::Basename::basename($need_file));
		close $LOG_FILEHANDLE;
	    }
	    $LOG_FILEHANDLE = $fh;
	    $LOG_FILEHANDLE->autoflush(1);
	    $FILENAME_OPENED = $need_file;
	};
	if($@) {
	    if(defined($LOG_FILEHANDLE)) {
		# keep writting to old log file, but warn user
		print $LOG_FILEHANDLE prepare_line('WARNING', sprintf("unable to create log file: %s", $@));
	    } else {
		# FIXME: nowhere to write logs (hours of trouble-shooting if daemonized...)
		die sprintf("unable to open log for writting [%s]: %s\n",
			    $need_file, $!);
	    }
	}
	setup_die_handler();
	setup_warn_handler();
    }
    $LOG_FILEHANDLE;
}

=head2 logit

Internal function that ensures Logger is sending data to the correct
file, and writes the actual log message to that file.  If there are
date or time codes from strftime(3) in the template, it will close and
re-open new logs when necessary.

=cut

sub logit {
    my ($line) = @_;
    my $fh = log_filehandle(filename_template());
    print $fh $line;
    $line;
}

=head2 setup_die_handler

Internal function called to setup handler for Perl pseudo-signal
__DIE__.

=cut

sub setup_die_handler {
    $SIG{__DIE__} = sub {
	chomp(my $msg = shift);
	error($msg);
	return 1;
    };
}

=head2 setup_warn_handler

Internal function called to setup handler for Perl pseudo-signal
__WARN__.

=cut

sub setup_warn_handler {
    $SIG{__WARN__} = sub {
	chomp(my $msg = shift);
	warning($msg);
	return 1;
    };
}

=head1 AUTHOR

Karrick S. McDermott, C<< <karrick at karrick.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ksm-logger at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=KSM-Logger>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

The Logger sets up signal handlers for the pseudo-signals __DIE__ and
__WARN__ signals.  This occurs when the first log entry is written, so
warn() and die() will not be automatically logged before the first
even is written to the log file.  This is normally not a problem
because many program, and most daemon programs, print out some line to
indicate program initialization and commencement.

    info("Initializing Foobar");


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
