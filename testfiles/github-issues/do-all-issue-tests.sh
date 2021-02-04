#!/bin/bash

$RIBOSCRIPTSDIR/testfiles/github-issues/iss1/do-iss1-tests.sh
if [ $? -eq 0 ]; then
   rm -rf rt-test
   echo "Success: all tests passed [do-all-issue-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-all-issue-tests.sh]"
   exit 1
fi
