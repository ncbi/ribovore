#!/bin/bash

$RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/github-issues/iss1/iss1.testin iss1-out
if [ $? -eq 0 ]; then
   rm -rf iss1-out
   echo "Success: all tests passed [do-iss1-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-iss1-tests.sh]"
   exit 1
fi
