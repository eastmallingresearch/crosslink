#!/bin/bash

#fix marker typing errors

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#example parameters
#CL_GROUP_MINLOD=5.0
#CL_GROUP_MATPATLOD=20.0
#CL_MATPAT_WEIGHTS="01P03"
source ${CL_CONF_FILE}

#make temporary directory for the output
MYTMPDIR=$(mktemp -d)

#fix typing errors
crosslink_group --inp=${CL_INPUT_FILE}\
                --outbase=${MYTMPDIR}/tmp_\
                --min_lod=${CL_GROUP_MINLOD}\
                --matpat_lod=${CL_GROUP_MATPATLOD}\
                --matpat_weights=${CL_MATPAT_WEIGHTS}

#aggregate markers into single lg again
cat ${MYTMPDIR}/tmp_???.loc | grep -v '^;' > ${MYTMPDIR}/all
NMARKERS=$(cat ${MYTMPDIR}/all | wc --lines)
echo "; group NONE markers ${NMARKERS}" > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/all >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp_???.loc ${MYTMPDIR}/all
rmdir ${MYTMPDIR}