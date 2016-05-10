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

cd /home/vicker/crosslink/ploscompbiol_data/simdata/test_maxlod

mkdir -p logs
mkdir -p figs

MAXJOBS=100

for X in 2.5 3.0 4.0 5.0 10.0 15.0 20.0 25.0
do
    for SAMPLENO in $(seq 201 230)
    do
        SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
        
        HOMEO_MINCOUNT=25
        HOMEO_MINLOD=2
        HOMEO_MAXLOD=${X}
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
done
