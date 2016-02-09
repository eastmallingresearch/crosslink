#!/bin/bash

#
# test refactored crosslink_group on rgxha data
# interactive lg splitting
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -u

FNAME=RGxHA
#FNAME=test
SEED=$1

RUN_REMOVE=0
RUN_GROUP=0
RUN_REFINE=0
RUN_IMPUTEMISSING=0
RUN_MAP=0
RUN_REMAP=1

#==========REMOVE=============
if [ "${RUN_REMOVE}" == "1" ]
then
    rm -f ${FNAME}_*.lo[cg]
fi

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

#===========REFINE===============
#group options
REF_MINLOD=35.0
REF_GLOB=${FNAME}_???_???_???_???_???
REF_IGNORECXR=1
REF_UNSPLIT=unsplit

if [ "${RUN_REFINE}" == "1" ]
then
    mkdir -p ${REF_UNSPLIT}

    for INPNAME in ${REF_GLOB}.loc
    do
        echo "${INPNAME}"
        crosslink_viewer --inp ${INPNAME} --datatype phased --minlod 5.0
    
        RET=$?
        
        #error
        if [ "${RET}" == 1 ]
        then
            echo crosslink_viewer error
            break
        fi

        #pressed ESCAPE to abort
        if [ "${RET}" == 100 ]
        then
            echo user abort
            break
        fi
        
        #pressed '0' to not split this LG further
        if [ "${RET}" == "10" ]
        then
            echo no further splitting
            continue
        fi
        
        #pressed '1' to apply further splitting to this LG
        if [ "${RET}" == "11" ]
        then
            echo "applying further splitting at LOD ${REF_MINLOD}"
        
            BASENAME=$(echo ${INPNAME} | sed 's/\.loc//g')
        
            crosslink_group --inp ${INPNAME}\
                            --outbase ${BASENAME}_\
                            --log ${BASENAME}.log\
                            --prng_seed ${SEED}\
                            --min_lod ${REF_MINLOD}\
                            --ignore_cxr ${REF_IGNORECXR} || break
                            
            mv ${INPNAME} ${BASENAME}.log ${REF_UNSPLIT}
        fi
    done
fi

#===========IMPUTE MISSING VALUES===============
#group options
IMP_MINLOD=0.1
IMP_GLOB=${FNAME}_*.loc
IMP_IGNORECXR=1
IMP_KNN=3

if [ "${RUN_IMPUTEMISSING}" == "1" ]
then
    for INPNAME in ${IMP_GLOB}
    do
        BASENAME=$(echo ${INPNAME} | sed 's/\.loc//g')
    
        echo ${INPNAME}
    
        crosslink_group --inp ${INPNAME}\
                        --outbase ${BASENAME}_knn\
                        --log ${BASENAME}_knn.log\
                        --prng_seed ${SEED}\
                        --min_lod ${IMP_MINLOD}\
                        --knn ${IMP_KNN}\
                        --ignore_cxr ${IMP_IGNORECXR} || break
    done
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

#==============REMAP====================
MAP_CYCLES=5
MAP_RANDOMISE=0
MAP_SKIP_ORDER1=1

#ga options
GA_ITERS=1000000
GA_OPTIMISE_DIST=0
GA_MST=1
GA_MST_MINLOD=1.0
GA_MST_NONHK=0

#single marker hop mutation
GA_PROB_HOP=0.333
GA_MAX_HOP=1.0
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

if [ "${RUN_REMAP}" == "1" ]
then
    mkdir -p final_frags

    for INPNAME in ${FNAME}_*knn000.loc2
    do
        BASENAME=$(echo ${INPNAME} | sed 's/\.loc2//g')
        
        echo "${INPNAME} ESC=abort 1=remap 0=accept 9=leave" 
        crosslink_viewer --inp ${INPNAME} --datatype imputed
    
        RET=$?
        
        #error
        if [ "${RET}" == 1 ]
        then
            echo crosslink_viewer error
            break
        fi

        #pressed ESCAPE to abort
        if [ "${RET}" == 100 ]
        then
            echo user abort
            break
        fi
        
        #pressed '0' to accept
        if [ "${RET}" == "10" ]
        then
            echo moving to final_frags directory
            mv ${INPNAME} final_frags
            continue
        fi

        #pressed '9' to leave
        if [ "${RET}" == "19" ]
        then
            echo leaving
            continue
        fi

        echo remapping...

        crosslink_map\
              --inp             ${BASENAME}.loc2\
              --out             ${BASENAME}.loc2\
              --log             ${BASENAME}.log2\
              --prng_seed       ${SEED}\
              --ga_gibbs_cycles ${MAP_CYCLES}\
              --randomise_order ${MAP_RANDOMISE}\
              --ga_iters         ${GA_ITERS}\
              --ga_optimise_dist ${GA_OPTIMISE_DIST}\
              --ga_skip_order1   ${MAP_SKIP_ORDER1}\
              --ga_use_mst       ${GA_MST}\
              --ga_mst_minlod    ${GA_MST_MINLOD}\
              --ga_mst_nonhk     ${GA_MST_NONHK}\
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
