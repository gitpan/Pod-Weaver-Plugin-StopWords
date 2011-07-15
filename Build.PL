
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Exporter' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Moose::Autobox' => '0.10',
    'PPI' => '0',
    'Pod::Elemental' => '0.102360',
    'Pod::Elemental::Selectors' => '0',
    'Pod::Elemental::Transformer::Nester' => '0',
    'Pod::Elemental::Transformer::Pod5' => '0',
    'Software::License::Perl_5' => '0',
    'Test::Differences' => '0.500',
    'Test::MockObject' => '1.09',
    'Test::More' => '0.96'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Dynamically add stopwords to your woven pod',
  'dist_author' => [
    'Randy Stauner <rwstauner@cpan.org>'
  ],
  'dist_name' => 'Pod-Weaver-Plugin-StopWords',
  'dist_version' => '1.004',
  'license' => 'perl',
  'module_name' => 'Pod::Weaver::Plugin::StopWords',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '0',
    'Moose::Autobox' => '0',
    'Pod::Weaver' => '3.101632',
    'Pod::Weaver::Role::Finalizer' => '0',
    'namespace::autoclean' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
