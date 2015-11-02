#!/bin/bash

#
# check hk imputation with perfect ordering
#

set -eu

./scripts2/make.sh

FNAME=test_gibbs_smallmap

#create map options
LGS=1
LGSIZE=200
MARKERS=35
SEED=0
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.0
ERROR=0.0
MAPFUNC=1

#gg_map
CYCLES=1
GA_ITERS=0
SAMPLES=500
BURNIN=100
PERIOD=5
PROB_SEQUENTIAL=1.0
PROB_UNIDIR=1.0
MIN_PROB_1=0.2
MIN_PROB_2=0.0
TWOPT_1=1.0
TWOPT_2=0.0
MIN_CTR=0

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
                  --lg 000\
                  --show_initial 0\
                  --map_func ${MAPFUNC}\
                  --ga_gibbs_cycles ${CYCLES}\
                  --ga_report 10\
                  --ga_iters ${GA_ITERS}\
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
                  --randomise_order 0\
                  --missing_hks 1\
                  --show_pearson 1\
                  --show_hkcheck 1\
                  --show_bits 1\
                  --show_width 30\
                  --show_height 40\
                  --pause 0

                  #--map ./testdata/${FNAME}.outmap\

cat ./testdata/test_gibbs_smallmap.log | grep 'final number of hk errors'
