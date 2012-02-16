#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'KSM::Logger' ) || print "Bail out!
";
}

diag( "Testing KSM::Logger $KSM::Logger::VERSION, Perl $], $^X" );
