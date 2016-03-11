#!/bin/bash

#merge two or more linkage groups

set -eu

CL_MERGELIST_FILE=$1
CL_INPUT_DIR=$2
CL_INPUT_BASE=$3
CL_OLD_DIR=$4
CL_CONF_FILE=$5

mkdir -p ${CL_OLD_DIR}

cat ${CL_MERGELIST_FILE} |\
while read LGLIST
do
    cl_merge_inner.sh\
        "${LGLIST}"\
        ${CL_INPUT_DIR}/${CL_INPUT_BASE}\
        ${CL_OLD_DIR}\
        ${CL_CONF_FILE}
done
