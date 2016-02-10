#!/bin/bash

#
# test hk imputation on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -u

FNAME=hktest001
SEED=$1

RUN_REMOVE=1
RUN_CREATE=1
RUN_SAMPLE=1
RUN_GROUP=1
RUN_MERGE=1
RUN_MAP=1

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_hk_imputation" ]
then
    echo unexpected working directory, aborting
    exit
fi

#===========remove previous results
if [ "${RUN_REMOVE}" == "1" ]
then
    rm ${FNAME}*
fi

#=========create map=========
MARKERS=100
NLGS=1
CENTIMORGANS=100.0
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

#==========GROUP==============
#group options
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_IGNORECXR=1      #whether to ignore cxr and rxc linkage which can be used for grouping but not phasing

if [ "${RUN_GROUP}" == "1" ]
then
    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_\
                    --log ${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --ignore_cxr ${GRP_IGNORECXR}
fi

#==========MERGE==============
#merge the two groups with a phase change for one parental genome

if [ "${RUN_MERGE}" == "1" ]
then
    cat ${FNAME}_000.loc > ${FNAME}_100.loc
    cat ${FNAME}_000.loc > ${FNAME}_101.loc
    cat ${FNAME}_000.loc > ${FNAME}_110.loc
    cat ${FNAME}_000.loc > ${FNAME}_111.loc
    cat ${FNAME}_001.loc                                      >> ${FNAME}_100.loc
    cat ${FNAME}_001.loc | sed 's/{00}/{01}/g; s/{11}/{10}/g' >> ${FNAME}_101.loc
    cat ${FNAME}_001.loc | sed 's/{00}/{10}/g; s/{11}/{01}/g' >> ${FNAME}_110.loc
    cat ${FNAME}_001.loc | sed 's/{00}/{xx}/g; s/{11}/{00}/g; s/{xx}/{11}/g' >> ${FNAME}_111.loc
fi

#==============MAP====================
MAP_CYCLES=5
MAP_RANDOMISE=1
MAP_SKIP_ORDER1=0

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

    for INPNAME in ${FNAME}_[0-9][0-9][0-9].loc
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
