#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#reinsert redundant markers after their respective framework marker

set -eu

CL_INPUT_DIR=$1
CL_REDUN_FILE=$2
CL_OUTPUT_DIR=$3

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.map
do
    OUTNAME=${CL_OUTPUT_DIR}/$(basename ${INPNAME})
        
    reinsert_redundant_map.py\
        --inp ${INPNAME}\
        --redun ${CL_REDUN_FILE}\
        > ${OUTNAME}
done
