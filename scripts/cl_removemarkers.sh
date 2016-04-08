#!/bin/bash

#
#filter out a set of one or more named markers
#

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_BADMARKER_FILE=$3

#make temporary directory
MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#remove "bad" markers
cat ${CL_INPUT_FILE}\
    | grep -vF -f ${CL_BADMARKER_FILE}\
    | cat\
    > ${MYTMPDIR}/tmp
    
cat ${MYTMPDIR}/tmp > ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp
rmdir ${MYTMPDIR}
