#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribotyper.p.testin rt-p-test
rm -rf rt-p-test
