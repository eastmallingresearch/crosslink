#!/bin/bash

#
# launch test runs to optimise hk imputation parameters
# run on cluster
#

set -eu

#minprob1 0 - 1
#minprob2 > 0, < .25
#probunidir  .05-.8
#probunordered >0, < 0.7
#probsequential 0-0.8
#samples 50-200
#twopt1 0 - 1
#twopt2 0 - 1
#burnin > 1

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/sample_data

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_hk' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=100
NUM_TRIALS=2000

#baseline parameters
GA_GIBBS_CYCLES=5
GA_ITERS=300000
GA_USE_MST=1
GA_MINLOD=10
GA_MST_NONHK=1
GA_OPTIMISE_METH=0
GA_PROB_HOP=0.333
GA_MAX_HOP=1.0
GA_PROB_MOVE=0.333
GA_MAX_MVSEG=1.0
GA_MAX_MVDIST=1.0
GA_PROB_INV=0.5
GA_MAX_SEG=1.0
GIBBS_PERIOD=1
GIBBS_SAMPLES=300
GIBBS_BURNIN=20
GIBBS_PROB_SEQUENTIAL=0.0
GIBBS_PROB_UNIDIR=1.0
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

#sweep through different parameter settings
TRIAL=1
while [ ${TRIAL} -le ${NUM_TRIALS} ]
do
    MYUID=$(printf "%010d" ${TRIAL})

    GIBBS_SAMPLES=$((RANDOM%600+1))
    GIBBS_BURNIN=$((RANDOM%100+1))
    vals=( $(python -c "import random as r; r.seed(${RANDOM}); x=r.random(); y=r.random(); z=r.random(); t=x+y+z; x/=t;y/=t;print x,y") )
    GIBBS_PROB_SEQUENTIAL=${vals[0]}
    GIBBS_PROB_UNIDIR=${vals[1]}
    vals=( $(python -c "import random as r; r.seed(${RANDOM}); print ' '.join([str(r.random()) for x in xrange(4)])") )
    GIBBS_MIN_PROB_1=${vals[0]}
    GIBBS_MIN_PROB_2=${vals[1]}
    GIBBS_TWOPT_1=${vals[2]}
    GIBBS_TWOPT_2=${vals[3]}
    
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
    export MYUID SAMPLE_DIR
    export GA_GIBBS_CYCLES GA_ITERS GA_USE_MST GA_MINLOD GA_MST_NONHK GA_OPTIMISE_METH
    export GA_PROB_HOP GA_MAX_HOP GA_PROB_MOVE GA_MAX_MVSEG GA_MAX_MVDIST GA_PROB_INV
    export GA_MAX_SEG GIBBS_PERIOD GIBBS_SAMPLES GIBBS_BURNIN GIBBS_PROB_SEQUENTIAL
    export GIBBS_PROB_UNIDIR GIBBS_MIN_PROB_1 GIBBS_MIN_PROB_2 GIBBS_TWOPT_1 GIBBS_TWOPT_2

    myqsub.sh ${SCRIPT_DIR}/test_hk.sh 
    
    TRIAL=$((TRIAL+1))
done
