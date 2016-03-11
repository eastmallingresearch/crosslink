#!/bin/bash

#phase a single linkage group

set -u

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2

#make temporary directory for the output
MYTMPDIR=$(mktemp -d)

crosslink_group --inp=${CL_INPUT_FILE}\
                --outbase=${MYTMPDIR}/tmp_\
                --min_lod=0.0
                
#aggregate markers into single file again
cat ${MYTMPDIR}/tmp_???.loc | grep -v '^;' > ${MYTMPDIR}/all
NMARKERS=$(cat ${MYTMPDIR}/all | wc --lines)
echo "; group NONE markers ${NMARKERS}" > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/all >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp_???.loc ${MYTMPDIR}/all
rmdir ${MYTMPDIR}
