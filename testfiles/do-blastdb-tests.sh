#!/bin/bash
set -e
$RIBOSCRIPTSDIR/ribotest -f $RIBOSCRIPTSDIR/testfiles/blastdb-univec.testin rt-blastdb
if [ $? -eq 0 ]; then
   echo "Success: all tests passed [do-blastdb-tests.sh]"
   exit 0
else 
   echo "FAIL: at least one test failed [do-blastdb-tests.sh]"
   exit 1
fi
