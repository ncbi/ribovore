#!/bin/bash

$RIBOSCRIPTSDIR/ribotest.pl --rmout -f $RIBOSCRIPTSDIR/testfiles/ribosensor.testin rs-test
if [ $? -eq 0 ]; then
   rm -rf rs-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi

