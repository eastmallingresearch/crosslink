#!/bin/bash

#
# test crosslink on simulated data
# small map, 1 LG
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster

set -eu

INPNAME=$1
FNAME=$(basename ${INPNAME/.loc/})
OUTDIR=$2

mkdir -p ${OUTDIR}

#group options
#SEED=1
GRP_RAND_ORDER=1
GRP_BITSTRINGS=1
MIN_LOD=1.0
MIN_LGS=1
KNN=5

#gg_map options
CYCLES=10
GG_RAND_ORDER=0

#ga options
SKIP_ORDER1=1
GA_ITERS=100000
OPTIMISE_DIST=0
GA_MST=0
GA_MINLOD=3.0
GA_NONHK=1
GA_BITSTRINGS=1

#mutation parameters
PROB_HOP=0.333
MAX_HOP=0.05
PROB_MOVE=0.5
MAX_MOVESEG=0.05
MAX_MOVEDIST=0.15
PROB_INV=0.5
MAX_SEG=0.1

#gibbs options
SAMPLES=300
BURNIN=20
PERIOD=1
PROB_SEQUENTIAL=0.75
PROB_UNIDIR=0.75
MIN_PROB_1=0.1
MIN_PROB_2=0.0
TWOPT_1=0.1
TWOPT_2=0.0
MIN_CTR=0

LGNAME=000

RUN_GROUP=1
RUN_ORDER=1
RUN_PLOT_ORDER=0

if [ "${RUN_GROUP}" == "1" ]
then
    #group markers into lgs, phase, make approx ordering
    gg_group --inp ${INPNAME}\
             --out ${OUTDIR}/${FNAME}_group.loc\
             --map ${OUTDIR}/${FNAME}_group.map\
             --log ${OUTDIR}/${FNAME}_group.log\
             --randomise_order ${GRP_RAND_ORDER}\
             --bitstrings ${GRP_BITSTRINGS}\
             --min_lgs ${MIN_LGS}\
             --min_lod ${MIN_LOD}\
             --knn ${KNN}
fi

if [ "${RUN_ORDER}" == "1" ]
then
    gg_map --inp ${OUTDIR}/${FNAME}_group.loc\
           --out ${OUTDIR}/${FNAME}_${LGNAME}.loc\
           --log ${OUTDIR}/${FNAME}_${LGNAME}.log\
           --map ${OUTDIR}/${FNAME}_${LGNAME}.map\
           --mstmap ${OUTDIR}/${FNAME}_${LGNAME}.mstmap\
           --lg ${LGNAME}\
           --bitstrings ${GA_BITSTRINGS}\
           --ga_gibbs_cycles ${CYCLES}\
           --ga_report 0\
           --ga_iters ${GA_ITERS}\
           --ga_use_mst ${GA_MST}\
           --ga_mst_minlod ${GA_MINLOD}\
           --ga_mst_nonhk ${GA_NONHK}\
           --ga_optimise_dist ${OPTIMISE_DIST}\
           --ga_skip_order1 ${SKIP_ORDER1}\
           --ga_prob_hop ${PROB_HOP}\
           --ga_max_hop ${MAX_HOP}\
           --ga_prob_move ${PROB_MOVE}\
           --ga_max_mvseg ${MAX_MOVESEG}\
           --ga_max_mvdist ${MAX_MOVEDIST}\
           --ga_prob_inv ${PROB_INV}\
           --ga_max_seg ${MAX_SEG}\
           --gibbs_report 0\
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
           
    #get just the marker order and cm posn
    tail -n +2 ${OUTDIR}/${FNAME}_${LGNAME}.map\
        | awk '{print $1,$4}'\
        > ${OUTDIR}/${FNAME}.order
fi

if [ "${RUN_PLOT_ORDER}" == "1" ]
then

    #compare order (assumes a single linkage group only)
    tail -n +2 smallmap/${FNAME}.map\
        | awk '{print $1,$5}'\
        > smallmap/${FNAME}.map.tmp
        
    tail -n +2 smallmap/${FNAME}_map_${LGNAME}.map\
        | awk '{print $1,$4}'\
        > smallmap/${FNAME}_map_${LGNAME}.map.tmp
        
    compare_map_order.py --map1 smallmap/${FNAME}.map.tmp\
                         --map2 smallmap/${FNAME}_map_${LGNAME}.map.tmp
fi
