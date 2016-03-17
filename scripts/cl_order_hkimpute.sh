#!/bin/bash

#order marker and impute hks all loc files in a directory

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_DIR=$2
CL_CONF_FILE=$3

source ${CL_CONF_FILE}

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    while [ "$(ps | grep  -c crosslink_map)" -ge "${CL_PARALLEL_JOBS}" ]
    do
        echo -n .
        sleep 1
    done

    OUTNAME=${CL_OUTPUT_DIR}/$(basename ${INPNAME})
    
    echo
    
    if [ "${CL_PARALLEL_JOBS}" -gt "1" ]
    then
        #run jobs in parallel
        echo starting $(basename ${INPNAME} .loc)
        nice   cl_order_hkimpute_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE} &
        sleep 0.1
    else
        #run jobs one at a time
        echo processing $(basename ${INPNAME} .loc)
        cl_order_hkimpute_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE}
    fi
done

if [ "${CL_PARALLEL_JOBS}" -gt "1" ]
then
    echo waiting for all jobs to complete...

    while [ "$(ps | grep  -c crosslink_map)" -gt "0" ]
    do
        echo -n .
        sleep 1
    done

    echo
    echo cl_order_hkmipute done
fi
