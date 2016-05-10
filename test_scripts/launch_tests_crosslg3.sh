#!/bin/bash

#
# launch test runs to optimise crosslg marker detection parameters
# run on cluster
# verify that optimise parameters work well on unseen test data
#

#scored 1.0 on all 200 tests

set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_crosslg3' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=100

for SAMPLENO in $(seq 201 400)
do
    SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
    
    HOMEO_MINCOUNT=25
    HOMEO_MINLOD=2
    HOMEO_MAXLOD=5
    MYUID=${SAMPLE_DIR}_${HOMEO_MINCOUNT}_${HOMEO_MINLOD}_${HOMEO_MAXLOD}
                
    while true
    do
        NJOBS=$(qstat | grep vicker | wc --lines)
        echo ${NJOBS}
        
        if [ "${NJOBS}" -lt "${MAXJOBS}" ]
        then
            break
        fi
        
        sleep 1
    done

    #launch the job
    export MYUID SAMPLE_DIR HOMEO_MINCOUNT HOMEO_MINLOD HOMEO_MAXLOD

    myqsub.sh ${SCRIPT_DIR}/test_crosslg.sh 
done
