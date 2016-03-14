#!/bin/bash

#calculate map positions without reordering markers or imputing hks

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_DIR=$2

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OUTNAME=${CL_OUTPUT_DIR}/$(basename --suffix=.loc ${INPNAME}).map
    crosslink_pos   --inp=${INPNAME}   --out=${OUTNAME}
done
