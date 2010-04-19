#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Artemis::SimNow' );
}

diag( "Testing Artemis::SimNow $Artemis::SimNow::VERSION, Perl $], $^X" );
