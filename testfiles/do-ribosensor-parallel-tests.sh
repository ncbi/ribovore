#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/ribosensor.p.testin rs-p-test
if [ $? -eq 0 ]; then
   echo "Success: all tests passed [do-ribosensor-parallel-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-ribosensor-parallel-tests.sh]"
   exit 1
fi
