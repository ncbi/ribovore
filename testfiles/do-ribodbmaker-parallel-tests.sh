#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribodbmaker.p.testin rdb-p-test
rm -rf rdb-p-test
