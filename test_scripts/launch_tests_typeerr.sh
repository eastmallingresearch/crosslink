#!/bin/bash

#
# launch test runs to optimise crosslg marker detection parameters
# run on cluster
#

#MATPATLOD anywhere from 10...20 made no difference with MINLOD=10

set -eu

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_typeerr' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=100

#sweep through different parameter settings
#for MATPATLOD in 10 12 14 16 18 20 25 30 40
for MATPATLOD in 25 30 40
do
    for SAMPLENO in $(seq 31 60)
    do
        SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
        while true
        do
            NJOBS=$(qstat | wc --lines)
            echo ${NJOBS}
            
            if [ "${NJOBS}" -lt "${MAXJOBS}" ]
            then
                break
            fi
            
            sleep 1
        done
    
        #launch the job
        export MATPATLOD SAMPLE_DIR
        echo ${MATPATLOD} ${SAMPLE_DIR}
        myqsub.sh ${SCRIPT_DIR}/test_typeerr.sh 
    done
done
