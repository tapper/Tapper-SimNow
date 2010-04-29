use inc::Module::Install;

name     'Artemis-SimNow';
all_from 'lib/Artemis/SimNow.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

install_script 'bin/artemis-simnow-start';

build_requires 'Test::More';

requires 'common::sense';
requires 'Artemis::Base'   => '0.010015';
requires 'Artemis::Remote' => '1.000018';
requires 'Log::Log4perl';


auto_install;

postamble("

live:
\t./script/dist_upload_wotan.sh dist
\tssh artemis\@billjones \"sudo /opt/artemis/bin/cpan Artemis::SimNow\"

devel:
\t./script/dist_upload_wotan.sh dist
");

WriteAll;

