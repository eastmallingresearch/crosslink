#!/bin/bash

#order marker and impute hks

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#example parameters
#CL_MAP_RANDOMISE=0
#CL_MAP_CYCLES=5
#CL_GA_ITERS=300000
#CL_GA_OPTIMISEDIST=0
#CL_GA_SKIPORDER1=1
#CL_GA_USEMST=5
#CL_GA_MSTMINLOD=3.0
#CL_GA_MSTNONHK=0
#CL_GA_PROBHOP=0.3333
#CL_GA_MAXHOP=1.0
#CL_GA_PROBMOVE=0.3333
#CL_GA_MAXMOVESEG=1.0
#CL_GA_MAXMOVEDIST=1.0
#CL_GA_PROBINV=0.5
#CL_GA_MAXSEG=1.0
#CL_GIBBS_SAMPLES=200
#CL_GIBBS_BURNIN=10
#CL_GIBBS_PERIOD=1
#CL_GIBBS_PROBSEQUEN=0.0
#CL_GIBBS_PROBUNIDIR=1.0
#CL_GIBBS_MINPROB1=0.1
#CL_GIBBS_MINPROB2=0.0
#CL_GIBBS_TWOPT1=0.1
#CL_GIBBS_TWOPT2=0.0
source ${CL_CONF_FILE}

#make temp dir
MYTMPDIR=$(mktemp -d)

crosslink_map\
    --inp=${CL_INPUT_FILE} --out=${MYTMPDIR}/tmp.loc\
    --randomise_order=${CL_MAP_RANDOMISE} --ga_gibbs_cycles=${CL_MAP_CYCLES}\
    --ga_iters=${CL_GA_ITERS} --ga_optimise_dist=${CL_GA_OPTIMISEDIST} --ga_skip_order1=${CL_GA_SKIPORDER1}\
    --ga_use_mst=${CL_GA_USEMST} --ga_mst_minlod=${CL_GA_MSTMINLOD} --ga_mst_nonhk=${CL_GA_MSTNONHK}\
    --ga_prob_hop=${CL_GA_PROBHOP} --ga_max_hop=${CL_GA_MAXHOP}\
    --ga_prob_move=${CL_GA_PROBMOVE} --ga_max_mvseg=${CL_GA_MAXMOVESEG} --ga_max_mvdist=${CL_GA_MAXMOVEDIST}\
    --ga_prob_inv=${CL_GA_PROBINV} --ga_max_seg=${CL_GA_MAXSEG}\
    --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
    --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
    --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
    --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}

#allow output file to overwrite input file
cat ${MYTMPDIR}/tmp.loc > ${CL_OUTPUT_FILE}

#clean up temporary dir
rm ${MYTMPDIR}/tmp.loc
rmdir ${MYTMPDIR}
