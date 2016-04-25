#!/bin/bash

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
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_crosslg' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=200
NUM_TRIALS=2000

TRIAL=1
while [ ${TRIAL} -le ${NUM_TRIALS} ]
do
    MYUID=$(printf "%010d" ${TRIAL})

    HOMEO_MINCOUNT=$(python -c "import random as r; print r.choice([5,10,15,20,25])")
    HOMEO_MINLOD=$(python -c "import random as r; print r.choice([0,0.5,1,1.5,2,2.5])")
    HOMEO_MAXLOD=$(python -c "import random as r; print r.choice([5,10,15,20,25])")
    
    SAMPLENO=$((RANDOM%200+1))
    
    SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
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
    
    TRIAL=$((TRIAL+1))
done
