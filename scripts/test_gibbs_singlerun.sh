#!/bin/bash

#
# check hk imputation with perfect ordering
#

set -eu

./scripts2/make.sh

FNAME=test_hkimputation

#create map options
LGS=1
LGSIZE=30
MARKERS=50
SEED=1
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=150
MISSING=0.0
ERROR=0.0
MAPFUNC=1

#gg_map
CYCLES=1
GA_ITERS=0
SAMPLES=1000
BURNIN=1
PERIOD=1
MIN_PROB=0.5

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

./scripts2/gg_map --inp ./testdata/${FNAME}.loc\
                  --out ./testdata/${FNAME}.outloc\
                  --log ./testdata/${FNAME}.log\
                  --lg 000\
                  --show_initial 0\
                  --map_func ${MAPFUNC}\
                  --ga_gibbs_cycles ${CYCLES}\
                  --ga_report 10\
                  --ga_iters ${GA_ITERS}\
                  --gibbs_report 10\
                  --gibbs_samples ${SAMPLES}\
                  --gibbs_burnin ${BURNIN}\
                  --gibbs_period ${PERIOD}\
                  --randomise_order 0\
                  --missing_hks 1\
                  --show_pearson 1\
                  --show_hkcheck 1\
                  --show_bits 2\
                  --show_width 30\
                  --show_height 30\
                  --pause 0\
                  --min_prob ${MIN_PROB}

                  #--map ./testdata/${FNAME}.outmap\

#tail -n +5 ./testdata/rlookup.loc > ./testdata/rlookup.loctmp
#diff ./testdata/rlookup.loctmp ./testdata/rlookup.outloc
