#!perl
# 
# This file is part of CPANPLUS-Dist-Mdv
# 
# This software is copyright (c) 2007 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 

use 5.010;
use strict;
use warnings;

use File::Find::Rule;
use Test::More;
use Test::Script;

my @files = File::Find::Rule->relative->file->name('*.pm')->in('lib');
plan tests => scalar(@files);

foreach my $file ( @files ) {
    my $module = $file;
    $module =~ s/[\/\\]/::/g;
    $module =~ s/\.pm$//;
    is( qx{ $^X -M$module -e "print '$module ok'" }, "$module ok", "$module loaded ok" );
}