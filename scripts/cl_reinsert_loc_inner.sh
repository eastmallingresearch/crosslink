#!/bin/bash

#reinsert redundant markers after their respective framework marker

set -eu

CL_INPUT_FILE=$1
CL_ALLLOCI_FILE=$2
CL_REDUN_FILE=$3
CL_OUTPUT_FILE=$4
CL_CONF_FILE=$5

source ${CL_CONF_FILE}

MYTMPDIR=$(mktemp -d)

#reinsert all redundant markers
#immediately after their associated framework marker
reinsert_redundant.py\
    --inp ${CL_INPUT_FILE}\
    --all ${CL_ALLLOCI_FILE}\
    --redun ${CL_REDUN_FILE}\
    > ${MYTMPDIR}/tmp
    
#rephase
crosslink_group --inp=${MYTMPDIR}/tmp\
                --outbase=${MYTMPDIR}/\
                --min_lod=0.0

#reimpute hks
crosslink_map\
  --inp=${MYTMPDIR}/000.loc --out=${CL_OUTPUT_FILE}\
  --ga_gibbs_cycles=1 --ga_iters=0 --ga_skip_order1=1\
  --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
  --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
  --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
  --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}

#clean up temp files
rm ${MYTMPDIR}/tmp ${MYTMPDIR}/000.loc
rmdir ${MYTMPDIR}

    
