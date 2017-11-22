#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

my $min_tv = 1.004000;
 
eval "use Test::Version $min_tv qw(version_all_ok ), {
        is_strict   => 1,
        has_version => 1,
        consistent  => 1,
    };
";
plan skip_all => "Test::Version 1.004000 required for testing version numbers" if $@;

version_all_ok();
done_testing();
