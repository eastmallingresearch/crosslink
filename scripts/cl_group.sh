#!/bin/bash

#group markers based on a simple lod threshold

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_DIR=$2
CL_GROUP_MINLOD=$3

mkdir -p ${CL_OUTPUT_DIR}

rm -f ${CL_OUTPUT_DIR}/*.loc

crosslink_group\
        --inp=${CL_INPUT_FILE}\
        --outbase=${CL_OUTPUT_DIR}/\
        --min_lod=${CL_GROUP_MINLOD}
