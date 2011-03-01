use inc::Module::Install;

name     'Tapper-SimNow';
all_from 'lib/Tapper/SimNow.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

install_script 'bin/tapper-simnow-start';

build_requires 'Test::More';
build_requires 'Test::Perl::Critic';

author_requires 'Module::Install::WriteAll';

requires 'common::sense';
requires 'Tapper::Base'    => '0.010015';
requires 'Tapper::Remote' => '1.000018';
requires 'Log::Log4perl';

auto_install;

WriteAll;

