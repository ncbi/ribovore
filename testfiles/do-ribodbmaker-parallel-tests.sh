#!/bin/bash

if [ -d $RIBOINSTALLDIR/vecscreen_plus_taxonomy ]; then
    $RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/ribodbmaker-vec.p.testin rdb-test
    if [ $? -eq 0 ]; then 
        echo "Success: all tests passed"
        exit 0
    else 
        echo "FAIL: at least one test failed"
        exit 1
    fi
else # $RIBOINSTALLDIR/vecscreen_plus_taxonomy does not exist, run test that does not require vecscreen_plus_taxonomy
    $RIBOSCRIPTSDIR/ribotest --rmout -f $RIBOSCRIPTSDIR/testfiles/ribodbmaker-novec.p.testin rdb-test
    if [ $? -eq 0 ]; then 
        echo "Success: all tests passed"
        exit 0
    else 
        echo "FAIL: at least one test failed"
        exit 1
    fi
fi    
