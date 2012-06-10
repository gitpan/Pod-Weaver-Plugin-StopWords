
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Dynamically add stopwords to your woven pod",
  "AUTHOR" => "Randy Stauner <rwstauner\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Moose::Autobox" => "0.10",
    "PPI" => 0,
    "Pod::Elemental" => "0.102360",
    "Pod::Elemental::Element::Pod5::Command" => 0,
    "Pod::Elemental::Selectors" => 0,
    "Pod::Elemental::Transformer::Nester" => 0,
    "Pod::Elemental::Transformer::Pod5" => 0,
    "Software::License::Perl_5" => 0,
    "Test::Differences" => "0.500",
    "Test::MockObject" => "1.09",
    "Test::More" => "0.96"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pod-Weaver-Plugin-StopWords",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Pod::Weaver::Plugin::StopWords",
  "PREREQ_PM" => {
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "Pod::Weaver" => "3.101632",
    "Pod::Weaver::Role::Finalizer" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.005",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



