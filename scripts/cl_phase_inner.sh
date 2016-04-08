#!/bin/bash

#phase a single linkage group

set -u

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2

#make temporary directory for the output
MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

crosslink_group --inp=${CL_INPUT_FILE}\
                --outbase=${MYTMPDIR}/\
                --min_lod=0.0
                
#aggregate markers into single file again
cat ${MYTMPDIR}/*.loc > ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/*.loc
rmdir ${MYTMPDIR}
