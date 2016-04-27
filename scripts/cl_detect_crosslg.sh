#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#detect polyploidy related cross linkage group markers

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

source ${CL_CONF_FILE}

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    while [ "$(ps | grep  -c crosslink_map)" -ge "${CL_PARALLEL_JOBS}" ]
    do
        echo -n .
        sleep 1
    done

    OUTNAME=${MYTMPDIR}/$(basename ${INPNAME}).out
    
    if [ "${CL_PARALLEL_JOBS}" -gt "1" ]
    then
        #run jobs in parallel
        echo starting $(basename ${INPNAME} .loc)
        nice   cl_detect_crosslg_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE} &
        sleep 0.1
    else
        #run jobs one at a time
        echo processing $(basename ${INPNAME} .loc)
        cl_detect_crosslg_inner.sh   ${INPNAME}   ${OUTNAME}   ${CL_CONF_FILE}
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

fi

#aggregate all detected cross linkage group marker names
cat ${MYTMPDIR}/*.out > ${CL_OUTPUT_FILE}
cat ${MYTMPDIR}/*.out.aux > ${CL_OUTPUT_FILE}.aux
rm -rf ${MYTMPDIR}
