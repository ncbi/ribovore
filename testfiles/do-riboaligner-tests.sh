#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/riboaligner.testin ra-test
rm -rf ra-test

