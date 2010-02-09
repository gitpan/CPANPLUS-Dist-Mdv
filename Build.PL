
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'a cpanplus backend to build mandriva rpms',
                       'script_files' => [],
                       'license' => 'perl',
                       'dist_name' => 'CPANPLUS-Dist-Mdv',
                       'dist_author' => [
                                          'Jerome Quelin'
                                        ],
                       'share_dir' => 'share',
                       'module_name' => 'CPANPLUS::Dist::Mdv',
                       'requires' => {
                                       'Pod::POM::View::Text' => 0,
                                       'Pod::POM' => 0,
                                       'List::Util' => 0,
                                       'File::ShareDir' => 0,
                                       'File::Find' => 0,
                                       'POSIX' => 0,
                                       'Text::Wrap' => 0,
                                       'List::MoreUtils' => 0,
                                       'File::Slurp' => 0,
                                       'File::Copy' => 0,
                                       'English' => 0,
                                       'CPANPLUS::Error' => 0,
                                       'IPC::Cmd' => 0,
                                       'Readonly' => 0,
                                       'perl' => '5.010',
                                       'Test::More' => 0,
                                       'File::Temp' => 0,
                                       'File::Basename' => 0,
                                       'CPANPLUS::Dist::Base' => 0
                                     }
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
