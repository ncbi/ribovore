#!/bin/bash

$RIBOSCRIPTSDIR/ribotest.pl -f $RIBOSCRIPTSDIR/testfiles/ribotyper.p.testin rt-p-test
if [ $? == 0 ]; then
   rm -rf rt-p-test
   echo "Success: all tests passed"
   exit 0
else 
   echo "FAIL: at least one test failed"
   exit 1
fi
