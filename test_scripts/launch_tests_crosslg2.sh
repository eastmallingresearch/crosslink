#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# launch test runs to optimise crosslg marker detection parameters
# run on cluster
#


set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_crosslg2' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=200

for SAMPLENO in $(seq 1 200)
do
    SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
    for HOMEO_MINCOUNT in 5 10 15 20 25
    do
        for HOMEO_MINLOD in 0.5 1 1.5 2 2.5
        do
            for HOMEO_MAXLOD in 5 10 15 20 25
            do
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
    done
done
