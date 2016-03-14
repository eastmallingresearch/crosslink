#!/bin/bash

#
#filter out a set of one or more named markers
#

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_BADMARKER_FILE=$3

#make temporary directory
MYTMPDIR=$(mktemp -d)

#remove "bad" markers and file header
cat ${CL_INPUT_FILE}\
    | grep -vF -f ${CL_BADMARKER_FILE}\
    | grep -v '^;'\
    | cat\
    > ${MYTMPDIR}/tmp.loc

#create new file header
echo "; group NONE markers $(cat ${MYTMPDIR}/tmp.loc | wc --lines )"\
    > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/tmp.loc >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp.loc
rmdir ${MYTMPDIR}
