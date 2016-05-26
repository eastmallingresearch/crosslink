#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# test method to fix lm <=> np typing errors
#

export PATH=${PATH}:/home/vicker/git_repos/rjvbio
export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts

set -u

RUN_CREATE=1
RUN_SAMPLE=1
RUN_GROUP=0
RUN_ORDER=0

FNAME=test_type_fixing2
#FNAME=test
SEED=2

#create map options
LGS=1
LGSIZE=0.001
MARKERS=10
PROB_HK=1.0
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.0
ERROR=0.0
TYPEERR=0.0
MAPFUNC=1          #1=haldane 2=kosambi

#group options
GRP_RAND_ORDER=1
MIN_LOD=9.0
MIN_LGS=${LGS}
KNN=5
FIX_TYPE=1

#gg_map options
CYCLES=10
GG_RAND_ORDER=0

#ga options
SKIP_ORDER1=1
GA_ITERS=200000
OPTIMISE_DIST=0
GA_MST=999
GA_MINLOD=3.0
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

if [ "${RUN_CREATE}" == "1" ]
then
    create_map  --out ./testdata/${FNAME}.map\
                --nmarkers ${MARKERS}\
                --nlgs ${LGS}\
                --prng_seed ${SEED}\
                --lg_size ${LGSIZE}\
                --prob_hk ${PROB_HK}\
                --prob_lm ${PROB_LM}
fi

if [ "${RUN_SAMPLE}" == "1" ]
then
    sample_map --inp ./testdata/${FNAME}.map\
               --out ./testdata/${FNAME}.loc\
               --orig ./testdata/${FNAME}.origloc\
               --nind ${POPSIZE}\
               --prng_seed ${SEED}\
               --prob_missing ${MISSING}\
               --prob_error ${ERROR}\
               --prob_type_error ${TYPEERR}\
               --map_func ${MAPFUNC}
fi

if [ "${RUN_GROUP}" == "1" ]
then
    gg_group --inp ./testdata/${FNAME}.loc\
             --out ./testdata/${FNAME}.outloc\
             --map ./testdata/${FNAME}.outmap\
             --log ./testdata/${FNAME}.log\
             --prng_seed ${SEED}\
             --map_func ${MAPFUNC}\
             --randomise_order ${GRP_RAND_ORDER}\
             --fix_marker_type ${FIX_TYPE}\
             --check_phase 1\
             --bitstrings 1\
             --show_pearson 1\
             --min_lgs ${MIN_LGS}\
             --min_lod ${MIN_LOD}\
             --knn ${KNN}
             #> ./testdata/${FNAME}.tmpmap
fi

if [ "${RUN_ORDER}" == "1" ]
then
    gg_map  --inp ./testdata/${FNAME}.outloc\
            --out ./testdata/${FNAME}.outloc2\
            --log ./testdata/${FNAME}.log2\
            --map ./testdata/${FNAME}.outmap2\
            --mstmap ./testdata/${FNAME}.mstmap\
            --lg 000\
            --show_initial 0\
            --prng_seed ${SEED}\
            --map_func ${MAPFUNC}\
            --randomise_order ${GG_RAND_ORDER}\
            --bitstrings 1\
            --show_pearson 1\
            --show_hkcheck 1\
            --show_bits 0\
            --show_width 30\
            --show_height 40\
            --pause 0\
            --ga_gibbs_cycles ${CYCLES}\
            --ga_report 1000\
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
            --gibbs_report 1\
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
fi
