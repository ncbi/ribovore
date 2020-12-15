#!/bin/bash
set -e
$RIBOSCRIPTSDIR/ribotest.pl -f $RIBOSCRIPTSDIR/testfiles/blastdb-univec.testin rt-blastdb
rm -rf rt-blastdb
