#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/ribotyper.testin rt-test
if [ $? -eq 0 ]; then
   echo "Success: all tests passed [do-ribotyper-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-ribotyper-tests.sh]"
   exit 1
fi
