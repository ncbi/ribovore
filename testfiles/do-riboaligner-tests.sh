#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/riboaligner.testin ra-test
if [ $? -eq 0 ]; then
   rm -rf ra-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi

