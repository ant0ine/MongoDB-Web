use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MongoDB::Web',
    license             => 'perl',
    dist_author         => q{Antoine Imbert <antoine.imbert@gmail.com>},
    dist_version_from   => 'lib/MongoDB/Web.pm',
    build_requires => {
        'Test::More' => 0,
        'URI' => 0,
        'Data::Dumper' => 0,
        'MongoDB' => 0,
        'Moose' => 0,
    },
    add_to_cleanup      => [ 'MongoDB-Web-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
