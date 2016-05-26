#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# generate test data for crosslink rflod viewer
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
#export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
#export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
#export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster

set -eu

if [ "$(pwd)" != "/home/vicker/crosslink/test_sdl" ]
then
    echo not in expected directory
    exit
fi

mkdir -p testdata

FNAME=testdata/test001
ERATE=0.01
MISS=0.01
NMARKERS=100
REP=1
DENSITY=1 #markers per centimorgan

LGSIZE=$(python -c "print float(${NMARKERS})/${DENSITY}")   #correct
POPSIZE=200

#create map with randomly placed markers
create_map --out ${FNAME}.map\
           --nmarkers ${NMARKERS}\
           --nlgs 1\
           --lg_size ${LGSIZE}\
           --prob_hk 0.333\
           --prob_lm 0.5\
           --hideposn 1
           
#simulate genotyping data from the markers
sample_map --inp ${FNAME}.map\
           --out ${FNAME}.loc\
           --orig ${FNAME}_orig.loc\
           --hide_hk_inheritance 1\
           --randomise_order 1\
           --nind ${POPSIZE}\
           --prob_missing ${MISS}\
           --prob_error ${ERATE}\
           --map_func 1
           

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
SKIP_ORDER1=1              #skip first ga round and go straight to gibbs
GA_ITERS=200000
OPTIMISE_DIST=0
GA_MST=0
GA_MINLOD=3.0
GA_NONHK=1
GA_BITSTRINGS=1

#mutation parameters
PROB_HOP=0.333            #move one marker
MAX_HOP=0.05
PROB_MOVE=0.5             #move a chunk of markers with optional invert
PROB_INV=0.5
MAX_MOVESEG=0.05
MAX_MOVEDIST=0.25
MAX_SEG=0.05              #invert a chunk of markers in-place

#gibbs options
SAMPLES=300
BURNIN=20
PERIOD=1
PROB_SEQUENTIAL=0.75       #prob resample sequentially along individual
PROB_UNIDIR=0.75           #prob only look at state of previous markers
MIN_PROB_1=0.1             #prevent prob of a state ever being zero during burnin
MIN_PROB_2=0.0
TWOPT_1=0.1                #use information from 2pt rf during burnin
TWOPT_2=0.0
MIN_CTR=0                  #min advantage of a state to be set (otherwise leave as unknown)

LGNAME=000

#group markers into lgs, phase, make approx ordering
gg_group --inp ${FNAME}.loc\
         --out ${FNAME}_group.loc\
         --map ${FNAME}_group.map\
         --log ${FNAME}_group.log\
         --randomise_order ${GRP_RAND_ORDER}\
         --bitstrings ${GRP_BITSTRINGS}\
         --min_lgs ${MIN_LGS}\
         --min_lod ${MIN_LOD}\
         --knn ${KNN}

#final ordering
gg_map --inp ${FNAME}_group.loc\
       --out ${FNAME}_${LGNAME}.loc\
       --log ${FNAME}_${LGNAME}.log\
       --map ${FNAME}_${LGNAME}.map\
       --mstmap ${FNAME}_${LGNAME}.mstmap\
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
