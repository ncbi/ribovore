#!/bin/bash

$RIBOSCRIPTSDIR/ribotest.pl -f $RIBOSCRIPTSDIR/testfiles/ribosensor.p.testin rs-p-test
if [ $? == 0 ]; then
    rm -rf rs-p-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi
