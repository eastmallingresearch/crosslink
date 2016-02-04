#!/bin/bash

#
# check hk imputation and map ordering
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts

set -u

FNAME=test_refactored
#FNAME=test
SEED=$1

RUN_CREATE=0
RUN_SAMPLE=0
RUN_GROUP=1
RUN_MAP=0

#create map options
LGS=10
LGSIZE=100
MARKERS=1000
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.0
ERROR=0.0
TYPEERR=0.0
MAPFUNC=1          #1=haldane 2=kosambi

#group options
GRP_MINLOD=5.0
GRP_KNN=5
GRP_CHKMATPAT=0
GRP_FIXMATPAT=0

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

if [ "${RUN_CREATE}" == "1" ]
then
    create_map --out ${FNAME}.map\
              --nmarkers ${MARKERS}\
              --nlgs ${LGS}\
              --prng_seed ${SEED}\
              --lg_size ${LGSIZE}\
              --prob_hk ${PROB_HK}\
              --prob_lm ${PROB_LM}
fi

if [ "${RUN_SAMPLE}" == "1" ]
then
    sample_map --inp ${FNAME}.map\
                  --out ${FNAME}.loc\
                  --orig ${FNAME}.origloc\
                  --nind ${POPSIZE}\
                  --prng_seed ${SEED}\
                  --prob_missing ${MISSING}\
                  --prob_error ${ERROR}\
                  --prob_type_error ${TYPEERR}\
                  --map_func ${MAPFUNC}
fi

if [ "${RUN_GROUP}" == "1" ]
then
    rm ${FNAME}_group???.loc ${FNAME}_group???.map

    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_group\
                    --mapbase ${FNAME}_group\
                    --log ${FNAME}_group.log\
                    --prng_seed ${SEED}\
                    --map_func ${MAPFUNC}\
                    --bitstrings 1\
                    --min_lod ${GRP_MINLOD}\
                    --detect_matpat_linkage ${GRP_CHKMATPAT}\
                    --fix_marker_type ${GRP_FIXMATPAT}\
                    --knn ${GRP_KNN}
fi

<<COMM
if [ "${RUN_MAP}" == "1" ]
then
    gg_map --inp ${FNAME}.outloc\
              --out ${FNAME}.outloc2\
              --log ${FNAME}.log2\
              --map ${FNAME}.outmap2\
              --mstmap ${FNAME}.mstmap\
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
COMM
