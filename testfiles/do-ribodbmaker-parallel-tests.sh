#!/bin/bash

$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribodbmaker.p.testin rdb-p-test
if [ $? == 0 ]; then
    rm -rf rdb-p-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi

