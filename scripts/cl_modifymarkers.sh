#!/bin/bash

#filter out a set of named markers
#manually convert marker types for sets of named markers

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#example parameters
#CL_BAD_MARKERS=conf/bad_markers
#CL_MAT2PAT_MARKERS=conf/mat2pat
#CL_PAT2MAT_MARKERS=conf/pat2mat
source ${CL_CONF_FILE}

#make temporary directory for the output
MYTMPDIR=$(mktemp -d)

#remove "bad" markers
cat ${CL_INPUT_FILE}\
    | grep -vF -f ${CL_BAD_MARKERS}\
    | cat\
    > ${MYTMPDIR}/tmp

#perform type switching
modify_markers.py\
    ${MYTMPDIR}/tmp\
    ${CL_MAT2PAT_MARKERS}\
    ${CL_PAT2MAT_MARKERS}\
    >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp
rmdir ${MYTMPDIR}
