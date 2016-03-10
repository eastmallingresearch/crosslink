#!/bin/bash

#impute missing values
#note: currently marker order is not preserved

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#example parameters
#CL_GROUP_MINLOD=5.0
#CL_GROUP_KNN=3
source ${CL_CONF_FILE}

#make temporary directory for the output
MYTMPDIR=$(mktemp -d)

crosslink_group --inp=${CL_INPUT_FILE}\
                --outbase=${MYTMPDIR}/tmp_\
                --min_lod=${CL_GROUP_MINLOD}\
                --knn=${CL_GROUP_KNN}

#aggregate markers into single file again
cat ${MYTMPDIR}/tmp_???.loc | grep -v '^;' > ${MYTMPDIR}/all
NMARKERS=$(cat ${MYTMPDIR}/all | wc --lines)
echo "; group NONE markers ${NMARKERS}" > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/all >> ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/tmp_???.loc ${MYTMPDIR}/all
rmdir ${MYTMPDIR}
