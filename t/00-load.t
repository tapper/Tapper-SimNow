#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tapper::SimNow' );
}

diag( "Testing Tapper::SimNow $Tapper::SimNow::VERSION, Perl $], $^X" );
