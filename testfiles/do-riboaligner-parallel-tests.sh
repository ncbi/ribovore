#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/riboaligner.p.testin ra-p-test
rm -rf ra-p-test
