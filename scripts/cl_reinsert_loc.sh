#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#reinsert redundant markers after their respective framework marker

set -eu

CL_INPUT_DIR=$1
CL_ALLLOCI_FILE=$2
CL_REDUN_FILE=$3
CL_OUTPUT_DIR=$4
CL_CONF_FILE=$5

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    cl_reinsert_loc_inner.sh\
        ${INPNAME}\
        ${CL_ALLLOCI_FILE}\
        ${CL_REDUN_FILE}\
        ${CL_OUTPUT_DIR}/$(basename ${INPNAME})\
        ${CL_CONF_FILE}
done
