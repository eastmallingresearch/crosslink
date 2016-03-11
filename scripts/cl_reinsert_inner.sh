#!/bin/bash

#reinsert redundant markers after their respective framework marker

set -eu

CL_INPUT_FILE=$1
CL_ALLLOCI_FILE=$2
CL_REDUN_FILE=$3
CL_OUTPUT_FILE=$4
CL_CONF_FILE=$5

#example parameters
#CL_MAP_RANDOMISE=0
#CL_MAP_CYCLES=5
#CL_GA_ITERS=300000
#CL_GA_OPTIMISEDIST=0
#CL_GA_SKIPORDER1=1
#CL_GA_USEMST=0
#CL_GA_MSTMINLOD=3.0
#CL_GA_MSTNONHK=0
#CL_GA_PROBHOP=0.3333
#CL_GA_MAXHOP=1.0
#CL_GA_PROBMOVE=0.3333
#CL_GA_MAXMOVESEG=1.0
#CL_GA_MAXMOVEDIST=1.0
#CL_GA_PROBINV=0.5
#CL_GA_MAXSEG=1.0
#CL_GIBBS_SAMPLES=300
#CL_GIBBS_BURNIN=20
#CL_GIBBS_PERIOD=1
#CL_GIBBS_PROBSEQUEN=0.0
#CL_GIBBS_PROBUNIDIR=1.0
#CL_GIBBS_MINPROB1=0.1
#CL_GIBBS_MINPROB2=0.0
#CL_GIBBS_TWOPT1=0.1
#CL_GIBBS_TWOPT2=0.0
source ${CL_CONF_FILE}

MYTMPDIR=$(mktemp -d)

#reinsert knn imputed version of all redundant markers
#immediately after their associated framework marker
#also filters out the header
reinsert_redundant.py\
    --inp ${CL_INPUT_FILE}\
    --all ${CL_ALLLOCI_FILE}\
    --redun ${CL_REDUN_FILE}\
    > ${MYTMPDIR}/tmp.loc
    
#create file header
echo "; group 000 markers $(cat ${MYTMPDIR}/tmp.loc | wc --lines )" > ${MYTMPDIR}/tmp2.loc
cat ${MYTMPDIR}/tmp.loc >> ${MYTMPDIR}/tmp2.loc

#rephase
crosslink_group --inp=${MYTMPDIR}/tmp2.loc\
                --outbase=${MYTMPDIR}/tmp2_\
                --min_lod=0.0

#reimpute hks
crosslink_map\
  --inp=${MYTMPDIR}/tmp2_000.loc --out=${CL_OUTPUT_FILE}\
  --ga_gibbs_cycles=1 --ga_iters=0 --ga_skip_order1=1\
  --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
  --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
  --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
  --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}

reinsert_redundant_map.py\
    --inp ${CL_INPUT_FILE/loc/map}\
    --redun ${CL_REDUN_FILE}\
    > ${CL_OUTPUT_FILE/loc/map}

#clean up temp files
rm ${MYTMPDIR}/tmp.loc ${MYTMPDIR}/tmp2.loc ${MYTMPDIR}/tmp2_000.loc
rmdir ${MYTMPDIR}

    
