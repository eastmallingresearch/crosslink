#!/bin/bash

#order marker and impute hks all loc files in a directory

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_DIR=$2
CL_CONF_FILE=$3

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OUTNAME=${CL_OUTPUT_DIR}/$(basename ${INPNAME})
    
    if [ "${CL_PARALLEL_JOBS}" == "1" ]
    then
        nice   cl_order_hkimpute_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE} &
    else
        cl_order_hkimpute_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE}
    fi
done

if [ "${CL_PARALLEL_JOBS}" == "1" ] 
then
    echo waiting for jobs to complete...

    while true
    do
        NJOBS=$(ps | grep  -c crosslink_map)
        if [ "${NJOBS}" == 0 ]
        then
            break
        fi
        echo ${NJOBS}
        sleep 10
    done

    echo done
fi
