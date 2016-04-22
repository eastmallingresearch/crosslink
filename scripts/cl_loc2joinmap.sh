#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#convert loc files into joinmap format

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_FILE=$2

#count number of markers and samples
NLOC=$(cat ${CL_INPUT_DIR}/*.loc | wc --lines)
NIND=$(cat ${CL_INPUT_DIR}/*.loc | head -n 1 | sed 's/.*} //g' | wc --chars)
NIND=$((NIND/3))

#header
echo "name = $(basename ${CL_OUTPUT_FILE} .loc)" >  ${CL_OUTPUT_FILE}
echo "popt = CP"       >> ${CL_OUTPUT_FILE}
echo "nloc = ${NLOC}"  >> ${CL_OUTPUT_FILE}
echo "nind = ${NIND}"  >> ${CL_OUTPUT_FILE}

#data
cat ${CL_INPUT_DIR}/*.loc >> ${CL_OUTPUT_FILE}

#if [ "${CL_NAME_FILE}" != "-" ]
#then
#    #append individual names
#    echo 'individual names:' >> ${CL_OUTPUT_FILE}
#    cat ${CL_NAME_FILE} >> ${CL_OUTPUT_FILE}
#fi
