#! /bin/bash

EXECDIR=$(dirname $0)
DISTFILES='Artemis*-*.*.tar.gz '

if [[ "$1" == "dist" ]]; then
    $EXECDIR/../../Artemis-Base/script/artemis_version_increment.pl $EXECDIR/../lib/Artemis/SimNow.pm
fi

cd $EXECDIR/..
if [[ -e MANIFEST ]]
then
  rm MANIFEST
fi
make manifest || exit -1

perl Makefile.PL || exit -1
make dist || exit -1

# -----------------------------------------------------------------
# It is important to not overwrite existing files.
# -----------------------------------------------------------------
# That guarantees that the version number is incremented so that we
# can be sure about version vs. functionality.
# -----------------------------------------------------------------

echo ""
echo '----- upload ---------------------------------------------------'
rsync -vv --progress --ignore-existing ${DISTFILES} artemis@wotan:/home/artemis/CPANSITE/CPAN/authors/id/A/AR/ARTEMIS/

echo ""
echo '----- re-index -------------------------------------------------'
ssh artemis@wotan /home/artemis/perl510/bin/cpansite -vv --site=/home/artemis/CPANSITE/CPAN --cpan=ftp://ftp.fu-berlin.de/unix/languages/perl/ index
ssh artemis@wotan /home/artemis/perl510/bin/cpan Artemis::SimNow
