#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/blastdb-univec.testin rt-blastdb
rm -rf rt-blastdb
