
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'CPANPLUS::Dist::Mdv',
  license       => 'perl',
  dist_abstract => "a\ cpanplus\ backend\ to\ build\ mandriva\ rpms",
  dist_name     => "CPANPLUS\-Dist\-Mdv",
  dist_author   => [
"Jerome\ Quelin",
  ],
  requires      => {
    "Pod::POM::View::Text" => '0',
    "Pod::POM" => '0',
    "List::Util" => '0',
    "File::Find" => '0',
    "POSIX" => '0',
    "Text::Wrap" => '0',
    "List::MoreUtils" => '0',
    "File::Slurp" => '0',
    "base" => '0',
    "File::Copy" => '0',
    "English" => '0',
    "ExtUtils::MakeMaker" => '0',
    "CPANPLUS::Error" => '0',
    "IPC::Cmd" => '0',
    "Readonly" => '0',
    "Test::More" => '0',
    "perl" => '5.010',
    "Module::Util" => '0',
    "File::Basename" => '0',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
