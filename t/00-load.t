#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Apache2::PhotoGal' ) || print "Bail out!\n";
}

diag( "Testing Apache2::PhotoGal $Apache2::PhotoGal::VERSION, Perl $], $^X" );
