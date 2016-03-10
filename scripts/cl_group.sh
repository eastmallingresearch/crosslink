#!/bin/bash

#group markers based on a simple lod threshold

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_BASE=$2
CL_GROUP_MINLOD=$3

echo ${CL_GROUP_MINLOD}

#remove any stale files
rm -f ${CL_OUTPUT_BASE}???.loc

crosslink_group\
        --inp=${CL_INPUT_FILE}\
        --outbase=${CL_OUTPUT_BASE}\
        --min_lod=${CL_GROUP_MINLOD}
