#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/riboaligner.p.testin ra-p-test
if [ $? -eq 0 ]; then
   echo "Success: all tests passed [do-riboaligner-parallel-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-riboaligner-parallel-tests.sh]"
   exit 1
fi
