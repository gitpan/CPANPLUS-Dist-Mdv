
use strict;
use warnings;

 BEGIN { require 5.010; } 

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CPANPLUS-Dist-Mdv',
  NAME      => 'CPANPLUS::Dist::Mdv',
  AUTHOR    => "Jerome\ Quelin",
  ABSTRACT  => "a\ cpanplus\ backend\ to\ build\ mandriva\ rpms",
  VERSION   => '2.093311',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
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
    "CPANPLUS::Error" => '0',
    "IPC::Cmd" => '0',
    "Readonly" => '0',
    "Test::More" => '0',
    "Module::Util" => '0',
    "File::Basename" => '0',
  },
  test => {TESTS => 't/*.t'}
);

