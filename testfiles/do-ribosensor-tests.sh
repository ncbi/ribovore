#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/ribosensor.testin rs-test
if [ $? -eq 0 ]; then
   rm -rf rs-test
   echo "Success: all tests passed [do-ribosensor-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-ribosensor-tests.sh]"
   exit 1
fi

