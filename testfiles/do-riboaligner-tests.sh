#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/riboaligner.testin ra-test
if [ $? -eq 0 ]; then
   rm -rf ra-test
   echo "Success: all tests passed [do-riboaligner-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-riboaligner-tests.sh]"
   exit 1
fi

