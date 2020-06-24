#!/bin/bash

$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/ribosensor.testin rs-test
if [ $? == 0 ]; then
   rm -rf rs-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi

