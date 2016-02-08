#!/bin/bash

#
# test refactored crosslink_group on rgxha data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -u

FNAME=RGxHA
#FNAME=test
SEED=$1

RUN_GROUP=1
RUN_MAP=0

#group options
GRP_MAPFUNC=1
GRP_MINLOD=10.0
GRP_KNN=0
GRP_MATPATLOD=20.0
GRP_IGNORECXR=1

#gg_map options
CYCLES=5
GG_RAND_ORDER=0

#ga options
SKIP_ORDER1=1
GA_ITERS=1000000
OPTIMISE_DIST=0
GA_MST=0
GA_MINLOD=5.0
GA_NONHK=1

#single marker hop mutation
PROB_HOP=0.333
MAX_HOP=0.05
#segment mutation parameters
PROB_MOVE=0.5
MAX_MOVESEG=0.05
MAX_MOVEDIST=0.1
PROB_INV=0.5
MAX_SEG=0.05

#gibbs options
SAMPLES=200
BURNIN=10
PERIOD=1
PROB_SEQUENTIAL=0.75
PROB_UNIDIR=0.75
MIN_PROB_1=0.1
MIN_PROB_2=0.0
TWOPT_1=0.1
TWOPT_2=0.0
MIN_CTR=0

if [ "${RUN_GROUP}" == "1" ]
then
    rm -f ${FNAME}_group???.loc ${FNAME}_group???.map

    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_group\
                    --mapbase ${FNAME}_group\
                    --log ${FNAME}_group.log\
                    --prng_seed ${SEED}\
                    --map_func ${GRP_MAPFUNC}\
                    --bitstrings 1\
                    --min_lod ${GRP_MINLOD}\
                    --matpat_lod ${GRP_MATPATLOD}\
                    --ignore_cxr ${GRP_IGNORECXR}\
                    --knn ${GRP_KNN}
fi

#gg_map options
CYCLES=5
GG_RAND_ORDER=0

#ga options
SKIP_ORDER1=1
GA_ITERS=1000000
OPTIMISE_DIST=0
GA_MST=0
GA_MINLOD=5.0
GA_NONHK=1

#single marker hop mutation
PROB_HOP=0.333
MAX_HOP=0.05
#segment mutation parameters
PROB_MOVE=0.5
MAX_MOVESEG=0.05
MAX_MOVEDIST=0.1
PROB_INV=0.5
MAX_SEG=0.05

#gibbs options
SAMPLES=200
BURNIN=10
PERIOD=1
PROB_SEQUENTIAL=0.75
PROB_UNIDIR=0.75
MIN_PROB_1=0.1
MIN_PROB_2=0.0
TWOPT_1=0.1
TWOPT_2=0.0
MIN_CTR=0

if [ "${RUN_MAP}" == "1" ]
then

    for INPNAME in ${FNAME}_*.loc
    do
        crosslink_map --inp ${INPNAME}\
              --out ${FNAME}.loc2\
              --log ${x}.log\
              --map ${x}.map2\
              --mstmap ${x}.mstmap\
              --prng_seed ${SEED}\
              --map_func ${GRP_MAPFUNC}\
              --bitstrings 1\
              --ga_gibbs_cycles ${CYCLES}\
              --ga_iters ${GA_ITERS}\
              --ga_use_mst ${GA_MST}\
              --ga_mst_minlod ${GA_MINLOD}\
              --ga_mst_nonhk ${GA_NONHK}\
              --ga_optimise_dist ${OPTIMISE_DIST}\
              --ga_skip_order1 ${SKIP_ORDER1}\
              --ga_cache 1\
              --ga_prob_hop ${PROB_HOP}\
              --ga_max_hop ${MAX_HOP}\
              --ga_prob_move ${PROB_MOVE}\
              --ga_max_mvseg ${MAX_MOVESEG}\
              --ga_max_mvdist ${MAX_MOVEDIST}\
              --ga_prob_inv ${PROB_INV}\
              --ga_max_seg ${MAX_SEG}\
              --gibbs_samples ${SAMPLES}\
              --gibbs_burnin ${BURNIN}\
              --gibbs_period ${PERIOD}\
              --gibbs_prob_sequential ${PROB_SEQUENTIAL}\
              --gibbs_prob_unidir ${PROB_UNIDIR}\
              --gibbs_min_ctr ${MIN_CTR}\
              --gibbs_min_prob_1 ${MIN_PROB_1}\
              --gibbs_min_prob_2 ${MIN_PROB_2}\
              --gibbs_twopt_1 ${TWOPT_1}\
              --gibbs_twopt_2 ${TWOPT_2}
    done
fi
