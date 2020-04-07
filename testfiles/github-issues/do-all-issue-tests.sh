#!/bin/bash
set -e 

if [ ! "$BASH_VERSION" ] ; then
    echo "Please do not use sh to run this script ($0), just execute it directly" 1>&2
    exit 1
fi

if [ -z "${RIBODIR}" ] ; then
    echo "RIBODIR environment variable is not set, set it as instructed during ribovore installation and rerun"
    exit 1
fi

$RIBODIR/testfiles/github-issues/iss1/do-iss1-tests.sh
