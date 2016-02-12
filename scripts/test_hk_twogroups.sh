#!/bin/bash

#
# test hk imputation on simulated data
# use cxr linkage during phasing
# split hks into two arbitrary groups before imputation
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -u

FNAME=hktest004
SEED=$1

RUN_REMOVE=1
RUN_CREATE=1
RUN_SAMPLE=1
RUN_SPLIT=1
RUN_GROUP=1
RUN_MAP=1

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_hk_imputation" ]
then
    echo unexpected working directory, aborting
    exit
fi

#===========remove previous results
if [ "${RUN_REMOVE}" == "1" ]
then
    rm -f ${FNAME}*
fi

#=========create map=========
MARKERS=100
NLGS=1
CENTIMORGANS=50.0
PROB_HK=1.0
PROB_LM=0.5

if [ "${RUN_CREATE}" == "1" ]
then
    create_map\
        --out ${FNAME}.map\
        --nmarkers ${MARKERS}\
        --nlgs ${NLGS}\
        --prng_seed ${SEED}\
        --lg_size ${CENTIMORGANS}\
        --prob_hk ${PROB_HK}\
        --prob_lm ${PROB_LM}
fi

#==============sample map ===================
POPSIZE=200
MISSING=0
ERROR=0
TYPEERR=0

if [ "${RUN_SAMPLE}" == "1" ]
then
    sample_map\
        --inp ${FNAME}.map\
        --out ${FNAME}.loc\
        --orig ${FNAME}.origloc\
        --nind ${POPSIZE}\
        --prng_seed ${SEED}\
        --prob_missing ${MISSING}\
        --prob_error ${ERROR}\
        --prob_type_error ${TYPEERR}
fi

#===============split=============
#split hks into two arbitrary groups
if [ "${RUN_SPLIT}" == "1" ]
then
    NGRP1=$((MARKERS/2))
    echo "; group 000 markers ${NGRP1}"         >  ${FNAME}_000.loc
    tail -n +2 ${FNAME}.loc | head -n ${NGRP1} >> ${FNAME}_000.loc
    echo "; group 001 markers ${NGRP1}"         >  ${FNAME}_001.loc
    tail -n +2 ${FNAME}.loc | tail -n ${NGRP1} >> ${FNAME}_001.loc
fi

#============GROUP==============
#group options
GRP_MINLOD=3.0       #lod to use for grouping and phasing
GRP_IGNORECXR=0      #whether to ignore cxr and rxc linkage which only provides partial phasing information

if [ "${RUN_GROUP}" == "1" ]
then
    for INPNAME in ${FNAME}_???.loc
    do
        BASENAME=$(echo ${INPNAME} | sed 's/\.loc//g')
        
        echo ${INPNAME}
        
        crosslink_group --inp ${INPNAME}\
                        --outbase ${BASENAME}_\
                        --log ${BASENAME}.log\
                        --prng_seed ${SEED}\
                        --min_lod ${GRP_MINLOD}\
                        --ignore_cxr ${GRP_IGNORECXR}
    done
fi

#==============MAP====================
MAP_CYCLES=5
MAP_RANDOMISE=0
MAP_SKIP_ORDER1=1

#ga options
GA_ITERS=300000
GA_OPTIMISE_DIST=0

#single marker hop mutation
GA_PROB_HOP=0.333
GA_MAX_HOP=1.0
#segment move parameters
GA_PROB_MOVE=0.5
GA_MAX_MOVESEG=1.0
GA_MAX_MOVEDIST=1.0
GA_PROB_INV=0.5
#segment inversion parameters
GA_MAX_SEG=1.0

#gibbs options
GIBBS_SAMPLES=200
GIBBS_BURNIN=10
GIBBS_PERIOD=1
GIBBS_PROB_SEQUENTIAL=1.0
GIBBS_PROB_UNIDIR=1.0
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

if [ "${RUN_MAP}" == "1" ]
then

    for INPNAME in ${FNAME}_???_???.loc
    do
        BASENAME=$(echo ${INPNAME} | sed 's/\.loc//g')
        
        echo ${INPNAME}
        
        crosslink_map\
              --inp             ${INPNAME}\
              --out             ${BASENAME}.loc2\
              --log             ${BASENAME}.log2\
              --prng_seed       ${SEED}\
              --ga_gibbs_cycles ${MAP_CYCLES}\
              --randomise_order ${MAP_RANDOMISE}\
              --ga_iters         ${GA_ITERS}\
              --ga_optimise_dist ${GA_OPTIMISE_DIST}\
              --ga_skip_order1   ${MAP_SKIP_ORDER1}\
              --ga_prob_hop      ${GA_PROB_HOP}\
              --ga_max_hop       ${GA_MAX_HOP}\
              --ga_prob_move     ${GA_PROB_MOVE}\
              --ga_max_mvseg     ${GA_MAX_MOVESEG}\
              --ga_max_mvdist    ${GA_MAX_MOVEDIST}\
              --ga_prob_inv      ${GA_PROB_INV}\
              --ga_max_seg       ${GA_MAX_SEG}\
              --gibbs_samples         ${GIBBS_SAMPLES}\
              --gibbs_burnin          ${GIBBS_BURNIN}\
              --gibbs_period          ${GIBBS_PERIOD}\
              --gibbs_prob_sequential ${GIBBS_PROB_SEQUENTIAL}\
              --gibbs_prob_unidir     ${GIBBS_PROB_UNIDIR}\
              --gibbs_min_prob_1      ${GIBBS_MIN_PROB_1}\
              --gibbs_min_prob_2      ${GIBBS_MIN_PROB_2}\
              --gibbs_twopt_1         ${GIBBS_TWOPT_1}\
              --gibbs_twopt_2         ${GIBBS_TWOPT_2} &
    done
fi
