#!/bin/bash

#
# launch test runs to optimise crosslg marker detection parameters
# run on cluster
#

#mincount=18 minlod=1.100000 maxlod=18.000000 seem best so far

set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/sample_data

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_crosslg' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=150

#group
export MINLOD=10.0       #form linkage groups using this linkage LOD threshold
export MATPATLOD=10.0   #correct marker typing errors using this LOD threshold
export KNN=3            #imputing missing values to the most common of the three nearest markers
export INIT_CYCLES=3    #how many gibbs-ga cycles

#sweep through different parameter settings
for HOMEO_MINCOUNT in 18 20 22
do
    for HOMEO_MINLOD in 0.9 1.0 1.1
    do
        for HOMEO_MAXLOD in 18 20 22
        do
            #HOMEO_MAXLOD=$(awk "BEGIN{print ${HOMEO_MINLOD}+${HOMEO_LODINC}}")
            
            for SAMPLENO in $(seq 21 40)
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
                export HOMEO_MINCOUNT HOMEO_MINLOD HOMEO_MAXLOD SAMPLE_DIR
                echo $HOMEO_MINCOUNT $HOMEO_MINLOD $HOMEO_MAXLOD $SAMPLE_DIR
                myqsub.sh ${SCRIPT_DIR}/test_crosslg.sh 
            done
        done
    done
done
