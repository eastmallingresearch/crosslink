#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
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
MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

crosslink_group --inp=${CL_INPUT_FILE}\
                --outbase=${MYTMPDIR}/\
                --min_lod=${CL_GROUP_MINLOD}\
                --knn=${CL_GROUP_KNN}

#aggregate markers into single file again
cat ${MYTMPDIR}/*.loc > ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/*.loc
rmdir ${MYTMPDIR}
