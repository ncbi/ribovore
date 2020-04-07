#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribotyper.testin rt-test
rm -rf rt-test
