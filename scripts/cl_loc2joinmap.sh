#!/bin/bash

#convert loc files into joinmap format

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_FILE=$2

#count number of markers and samples
NLOC=$(cat ${CL_INPUT_DIR}/*.loc | wc --lines)
NIND=$(cat ${CL_INPUT_DIR}/*.loc | head -n 1 | sed 's/.*} //g' | wc --chars)
NIND=$((NIND/3))

#header
echo "name = $(basename --suffix=.loc ${CL_OUTPUT_FILE})" >  ${CL_OUTPUT_FILE}
echo "popt = CP"       >> ${CL_OUTPUT_FILE}
echo "nloc = ${NLOC}"  >> ${CL_OUTPUT_FILE}
echo "nind = ${NIND}"  >> ${CL_OUTPUT_FILE}

#data
cat ${CL_INPUT_DIR}/*.loc >> ${CL_OUTPUT_FILE}

#could append individual names here
