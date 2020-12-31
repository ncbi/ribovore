#!/bin/bash

RETVAL=0;

for t in \
    do-ribotyper-parallel-tests.sh \
    do-riboaligner-parallel-tests.sh \
    do-ribosensor-parallel-tests.sh \
    do-ribodbmaker-parallel-tests.sh \
    ; do
    sh $RIBOSCRIPTSDIR/testfiles/$t
    if [ $? -ne 0 ]; then
        RETVAL=1;
    fi   
done

if [ $RETVAL -eq 0 ]; then
   echo "Success: all tests passed [do-parallel-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-parallel-tests.sh]"
   exit 1
fi
