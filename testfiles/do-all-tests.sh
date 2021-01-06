#!/bin/bash

RETVAL=0;

# If you want to test -p option for parallelization, add
# do-parallel-tests.sh to the following for loop.
# Note: this test requires qsub is in your path and qsub options are
# configured similarly to ncbi cluster, email eric.nawrocki@nih.gov
# for information on how to configure for different clusters
for t in \
    do-ribotyper-tests.sh \
    do-riboaligner-tests.sh \
    do-ribosensor-tests.sh \
    do-ribodbmaker-tests.sh \
    github-issues/do-all-issue-tests.sh \
    ; do
    sh $RIBOSCRIPTSDIR/testfiles/$t
    if [ $? -ne 0 ]; then
        RETVAL=1;
    fi   
done

if [ $RETVAL -eq 0 ]; then
   echo "Success: all tests passed [do-ribotyper-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-ribotyper-tests.sh]"
   exit 1
fi
