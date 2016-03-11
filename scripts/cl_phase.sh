#!/bin/bash

#phase all loc files in a given directory

set -u

CL_INPUT_DIR=$1
CL_OUTPUT_DIR=$2

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OUTNAME=${CL_OUTPUT_DIR}/$(basename ${INPNAME})
    cl_phase_inner.sh   ${INPNAME}   ${OUTNAME}
done
