#!/bin/bash
set -e
$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribodbmaker.testin rdb-test
rm -rf rdb-test
