#!/bin/bash

$RIBOSCRIPTSDIR/testfiles/github-issues/iss1/do-iss1-tests.sh
if [ $? == 0 ]; then
   rm -rf rt-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi
