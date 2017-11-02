use strict;
use warnings;
use ExtUtils::MakeMaker 6.46;

my $repo = "https://github.com/dleidert/Apache2-PhotoGal";

WriteMakefile(
    NAME             => 'Apache2::PhotoGal',
    AUTHOR           => q{Danial Leidert <dleidert@wgdd.de>},
    VERSION_FROM     => 'lib/Apache2/PhotoGal.pm',
    ABSTRACT_FROM    => 'lib/Apache2/PhotoGal.pm',
    LICENSE          => 'artistic',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0'
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Apache2::Reload' => '0'
    },
    META_MERGE => {
        'meta-spec' => {
             version => '2'
        },
        resources => {
            repository => {
                type => 'git',
                url => $repo . '.git',
                web => $repo,
            },
            bugtracker => {
                web => $repo . '/issues',
                mailto => 'dleidert@wgdd.de'
            }
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Apache2-PhotoGal-*' },
);