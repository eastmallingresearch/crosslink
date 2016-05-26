#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# test map ordering
#

set -u

./scripts2/make.sh

FNAME=test_ga

#create map options
LGS=1
LGSIZE=2000            #200 => suboptimal ordering, 2000 => hangs in print_map
MARKERS=1000
SEED=$1
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.0
ERROR=0.0
MAPFUNC=1

#gg_map
CYCLES=1
GA_ITERS=1000000

#gibbs sampler parameters
SAMPLES=0
BURNIN=500
PERIOD=10
PROB_SEQUENTIAL=0.5
PROB_UNIDIR=0.5
MIN_PROB_1=0.2
MIN_PROB_2=0.0
TWOPT_1=1.0
TWOPT_2=0.5
MIN_CTR=50

./scripts2/create_map --out ./testdata/${FNAME}.map\
                      --nmarkers ${MARKERS}\
                      --nlgs ${LGS}\
                      --prng_seed ${SEED}\
                      --lg_size ${LGSIZE}\
                      --prob_hk ${PROB_HK}\
                      --prob_lm ${PROB_LM}

./scripts2/sample_map --inp ./testdata/${FNAME}.map\
                      --out ./testdata/${FNAME}.loc\
                      --nind ${POPSIZE}\
                      --prng_seed ${SEED}\
                      --prob_missing ${MISSING}\
                      --prob_error ${ERROR}\
                      --map_func ${MAPFUNC}

#gdb --args \

./scripts2/gg_map --inp ./testdata/${FNAME}.loc\
                  --out ./testdata/${FNAME}.outloc\
                  --log ./testdata/${FNAME}.log\
                  --map ./testdata/${FNAME}.outmap\
                  --lg 000\
                  --show_initial 0\
                  --map_func ${MAPFUNC}\
                  --ga_gibbs_cycles ${CYCLES}\
                  --ga_report 10\
                  --ga_iters ${GA_ITERS}\
                  --ga_rcache 1\
                  --ga_bitstrings 1\
                  --ga_prob_swap 0.333\
                  --ga_prob_seg 0.0\
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
                  --gibbs_twopt_2 ${TWOPT_2}\
                  --prng_seed ${SEED}\
                  --randomise_order 1\
                  --missing_hks 0\
                  --show_pearson 1\
                  --show_hkcheck 1\
                  --show_bits 0\
                  --show_width 30\
                  --show_height 40\
                  --pause 0

                  
cat ./testdata/${FNAME}.log | grep -e 'final number of hk errors' -e 'final pearson' -e 'still set to missing'
cat ./testdata/${FNAME}.log | awk 'NF==3{print}' > ./testdata/${FNAME}.ga_log
cat ./testdata/${FNAME}.log | awk 'NF==4{print}' > ./testdata/${FNAME}.gibbs_log
tail -n +2 ./testdata/${FNAME}.outmap | awk '{print substr($1,6),$4}' > ./testdata/${FNAME}.cmpmap
