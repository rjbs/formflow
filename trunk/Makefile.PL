use strict;
use warnings;
use inc::Module::Install;

name 'Formflow';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More' => 0;

requires 'Params::Util'             => '0.15';
requires 'Sub::Install'             => 0;
requires 'Data::FormValidator'      => 0;
requires 'Class::Accessor::Chained' => 0;

WriteAll;
