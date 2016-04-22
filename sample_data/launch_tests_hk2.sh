#!/bin/bash

#
# launch test runs to optimise hk imputation parameters
# run on cluster
#

set -eu

#minprob1 0.1
#minprob2 0
#probunidir     1
#probunordered  0
#probsequential 0
#samples 200
#twopt1 0 - 1
#twopt2 1
#burnin 5

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/sample_data

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${SCRIPT_DIR}

#check working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/test_hk2' ]
then
    echo wrong working directory
    exit
fi

mkdir -p logs
mkdir -p figs

MAXJOBS=100
NUM_TRIALS=3000

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

    GIBBS_SAMPLES=$((RANDOM%150+50))
    GIBBS_BURNIN=5
    GIBBS_PROB_SEQUENTIAL=0.0
    GIBBS_PROB_UNIDIR=$(python -c "import random as r; r.seed(${RANDOM}); print r.random()")
    GIBBS_MIN_PROB_1=0.1
    GIBBS_MIN_PROB_2=$(python -c "import random as r; r.seed(${RANDOM}); print r.random()*0.25")
    GIBBS_TWOPT_1=$(python -c "import random as r; r.seed(${RANDOM}); print r.random()")
    GIBBS_TWOPT_2=$(python -c "import random as r; r.seed(${RANDOM}); print r.random()")
    
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
