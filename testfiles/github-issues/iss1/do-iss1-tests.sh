#!/bin/bash

$RIBODIR/ribotest.pl -f $RIBODIR/testfiles/github-issues/iss1/iss1.testin iss1-out
if [ $? == 0 ]; then
   rm -rf iss1-out
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi
