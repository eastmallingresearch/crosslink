#!/bin/bash

#
# test crosslink on simulated data
#

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/compare_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

#NSAMPLES=10
MAXJOBS=200

for SAMPLENO in $(seq 21 40)
do
    #wait for space in the queue
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
    
    SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
    export SAMPLE_DIR
    myqsub.sh ${SCRIPTDIR}/run_lepmap.sh 
    myqsub.sh ${SCRIPTDIR}/run_tmap.sh 
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_record 
    #myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_seriation
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_rcd
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_ug
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_approx 
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_full
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_refine
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_global
done
