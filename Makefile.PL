
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CPANPLUS-Dist-Mdv',
  NAME      => 'CPANPLUS::Dist::Mdv',
  AUTHOR    => 'Jerome\ Quelin',
  ABSTRACT  => 'a\ cpanplus\ backend\ to\ build\ mandriva\ rpms',
  VERSION   => '1.2.1',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Pod::POM::View::Text" => '0',
    "Pod::POM" => '0',
    "Test::Script" => '0',
    "List::Util" => '0',
    "POSIX" => '0',
    "Text::Wrap" => '0',
    "List::MoreUtils" => '0',
    "File::Slurp" => '0',
    "base" => '0',
    "File::Copy" => '0',
    "File::Find::Rule" => '0',
    "CPANPLUS::Error" => '0',
    "IPC::Cmd" => '0',
    "Readonly" => '0',
    "Test::More" => '0',
    "perl" => '5.010',
    "Module::Util" => '0',
    "File::Basename" => '0',
  },
);
