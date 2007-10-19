#!perl
#
# This file is part of CPANPLUS::Dist::Mdv.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
    module_name         => 'CPANPLUS::Dist::Mdv',
    dist_author         => 'Jerome Quelin <jquelin@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/CPANPLUS/Dist/Mdv.pm',
    add_to_cleanup => [
        'CPANPLUS-Dist-Mdv-*', 'MANIFEST.bak',
        map { ( '*/' x $_ ) . '*~' } 0..5 ],
    script_files   => [ ],
    build_requires => {
        perl              => '5.008',
        'CPANPLUS'        => 0,
        'IPC::Cmd'        => 0,
        'Readonly'        => 0,
        'Test::More'      => 0,
    },
    requires       => {
        'CPANPLUS'        => 0,
        'IPC::Cmd'        => 0,
        'Readonly'        => 0,
    },
);

$builder->create_build_script();