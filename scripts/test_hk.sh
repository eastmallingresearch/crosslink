#!/bin/bash

#
# test hk imputation on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -u

FNAME=hktest001
SEED=$1

RUN_CREATE=0
RUN_SAMPLE=0
RUN_GROUP=0
RUN_MAP=0

#=========create map=========
MARKERS=20
NLGS=1
CENTIMORGANS=1
PROB_HK=1.0
PROB_LM=0.0

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

<<COMM
echo sample_map
./scripts/sample_map --inp ./testdata/${FNAME}.map\
                      --out ./testdata/${FNAME}.loc\
                      --orig ./testdata/${FNAME}.origloc\
                      --nind ${POPSIZE}\
                      --prng_seed ${SEED}\
                      --prob_missing ${MISSING}\
                      --prob_error ${ERROR}\
                      --map_func ${MAPFUNC}

#==========GROUP==============
#group options
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_MATPATLOD=20.0   #lod to use for detecting mistyped markers
GRP_IGNORECXR=1      #whether to ignore cxr and rxc linkage which can be used for grouping but not phasing

if [ "${RUN_GROUP}" == "1" ]
then
    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_\
                    --log ${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --matpat_lod ${GRP_MATPATLOD}\
                    --ignore_cxr ${GRP_IGNORECXR}
fi


#==============MAP====================
MAP_CYCLES=5
MAP_RANDOMISE=0
MAP_SKIP_ORDER1=1

#ga options
GA_ITERS=1000000
GA_OPTIMISE_DIST=0

#single marker hop mutation
GA_PROB_HOP=0.333
GA_MAX_HOP=0.5
#segment move parameters
GA_PROB_MOVE=0.5
GA_MAX_MOVESEG=0.5
GA_MAX_MOVEDIST=0.5
GA_PROB_INV=0.5
#segment inversion parameters
GA_MAX_SEG=0.5

#gibbs options
GIBBS_SAMPLES=200
GIBBS_BURNIN=10
GIBBS_PERIOD=1
GIBBS_PROB_SEQUENTIAL=0.75
GIBBS_PROB_UNIDIR=0.75
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

if [ "${RUN_MAP}" == "1" ]
then

    for INPNAME in ${FNAME}_*knn000.loc
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
COMM
