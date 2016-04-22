#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#try multiple reorderings of the maps and keep the best one

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_DIR=$2
CL_NUMB_TRIALS=$3
CL_PARALLEL_JOBS=$4

shift 4

mkdir -p ${CL_OUTPUT_DIR}

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    while [ "$(ps | grep -c cl_ref.sh)" -ge "${CL_PARALLEL_JOBS}" ]
    do
        sleep 1
    done

    OUTNAME=${CL_OUTPUT_DIR}/$(basename ${INPNAME})
    
    if [ "${CL_PARALLEL_JOBS}" -gt "1" ]
    then
        #run jobs in parallel
        echo starting $(basename ${INPNAME})
        nice   cl_ref.sh ${INPNAME} ${OUTNAME} ${CL_NUMB_TRIALS} $@ &
        sleep 0.1
    else
        #run jobs one at a time
        echo processing $(basename ${INPNAME})
        cl_ref.sh ${INPNAME} ${OUTNAME} ${CL_NUMB_TRIALS} $@
    fi
done

if [ "${CL_PARALLEL_JOBS}" -gt "1" ]
then
    echo waiting for all jobs to complete...

    while [ "$(ps | grep -c cl_ref.sh)" -gt "0" ]
    do
        sleep 1
    done

    echo done
fi
