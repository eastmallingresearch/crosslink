#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#group markers based on a simple lod threshold

set -eu

#allow checking the script can be found in the path
if [ "$1" == "--check" ]
then
    exit 0
fi

CL_INPUT_FILE=$1
CL_OUTPUT_DIR=$2
CL_GROUP_MINLOD=$3

mkdir -p ${CL_OUTPUT_DIR}

rm -f ${CL_OUTPUT_DIR}/*.loc  ${CL_OUTPUT_DIR}/*.map

crosslink_group\
        --inp=${CL_INPUT_FILE}\
        --outbase=${CL_OUTPUT_DIR}/\
        --min_lod=${CL_GROUP_MINLOD}
