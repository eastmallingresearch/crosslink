#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# launch test runs to optimise hk imputation parameters
# run on cluster
#

set -eu

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_twopt' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=120

#baseline parameters
GA_GIBBS_CYCLES=5
GA_ITERS=200000
GA_USE_MST=3
GA_MINLOD=10
GA_MST_NONHK=0
GA_OPTIMISE_METH=0
GA_PROB_HOP=0.333
GA_MAX_HOP=0.0
GA_PROB_MOVE=0.333
GA_MAX_MVSEG=1.0
GA_MAX_MVDIST=1.0
GA_PROB_INV=0.5
GA_MAX_SEG=1.0
GIBBS_PERIOD=1
GIBBS_SAMPLES=300
GIBBS_BURNIN=10
GIBBS_PROB_SEQUENTIAL=0.0
GIBBS_PROB_UNIDIR=1.0
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

NREPS=5

#sweep through different parameter settings
for X in 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
do
    for SAMPLENO in $(seq 101 130)
    do
        for REP in $(seq 1 ${NREPS})
        do
            GIBBS_SAMPLES=300
            GIBBS_BURNIN=5
            GIBBS_PROB_SEQUENTIAL=0.0
            GIBBS_PROB_UNIDIR=1.0
            GIBBS_MIN_PROB_1=0.1
            GIBBS_MIN_PROB_2=0.0
            GIBBS_TWOPT_1=0.5
            GIBBS_TWOPT_2=${X}
            
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
            export SAMPLE_DIR
            export GA_GIBBS_CYCLES GA_ITERS GA_USE_MST GA_MINLOD GA_MST_NONHK GA_OPTIMISE_METH
            export GA_PROB_HOP GA_MAX_HOP GA_PROB_MOVE GA_MAX_MVSEG GA_MAX_MVDIST GA_PROB_INV
            export GA_MAX_SEG GIBBS_PERIOD GIBBS_SAMPLES GIBBS_BURNIN GIBBS_PROB_SEQUENTIAL
            export GIBBS_PROB_UNIDIR GIBBS_MIN_PROB_1 GIBBS_MIN_PROB_2 GIBBS_TWOPT_1 GIBBS_TWOPT_2

            myqsub.sh ${SCRIPT_DIR}/test_generic.sh
        done
    done
done
