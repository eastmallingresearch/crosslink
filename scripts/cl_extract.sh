#!/bin/bash

#extract the nonredundant markers

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_REDUN_FILE=$3

#make temporary directory for the output
MYTMPDIR=$(mktemp -d)

#get list of just redundant marker names
awk '{print $1}' ${CL_REDUN_FILE} | sort -u > ${MYTMPDIR}/redun

#exclude redundant markers from input data
cat ${CL_INPUT_FILE}\
    | grep -vF -f ${MYTMPDIR}/redun\
    | grep -v '^;'\
    | cat\
    > ${MYTMPDIR}/tmp.loc

#create file header
echo "; group 000 markers $(cat ${MYTMPDIR}/tmp.loc | wc --lines)" > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/tmp.loc >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/redun ${MYTMPDIR}/tmp.loc
rmdir ${MYTMPDIR}
