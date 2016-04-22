#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#merge two or more linkage groups

set -eu

CL_INPUT_DIR=$1
CL_MERGELIST_FILE=$2
CL_OUTPUT_DIR=$3
CL_CONF_FILE=$4

cat ${CL_MERGELIST_FILE} |\
while read LGLIST
do
    cl_merge_inner.sh   ${CL_INPUT_DIR}   "${LGLIST}"   ${CL_OUTPUT_DIR}   ${CL_CONF_FILE}
done
