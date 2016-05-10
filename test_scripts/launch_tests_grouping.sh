#!/bin/bash

#
# launch test runs to optimise crosslg marker detection parameters
# run on cluster
#

#minlod 9...14 is best

set -eu

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_group' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=100

#group
export MINLOD       #form linkage groups using this linkage LOD threshold
export NONHK        #whether to prioritise nonhk edges for MST approx ordering

#sweep through different parameter settings
for MINLOD in 3 4 5 6 7 9 11 14 20 25 30
do
    for SAMPLENO in $(seq 1 30)
    do
        export SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
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
    
        #launch the jobs
        NONHK=0
        echo ${MINLOD} ${NONHK} ${SAMPLE_DIR}
        myqsub.sh ${SCRIPT_DIR}/test_grouping.sh 

        NONHK=1
        echo ${MINLOD} ${NONHK} ${SAMPLE_DIR}
        myqsub.sh ${SCRIPT_DIR}/test_grouping.sh 
    done
done
