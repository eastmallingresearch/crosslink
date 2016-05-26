#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# test create_map and sample_map
#

set -eu

./scripts2/make.sh

FNAME=test1

#create map options
LGS=4
LGSIZE=100
MARKERS=30
SEED=5
POPN=100
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=100
MISSING=0.0
ERROR=0.0

#gg_map
CYCLES=4
GA_ITERS=20000
SAMPLES=500
BURNIN=500
PERIOD=500
MIN_PROB=0.001

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
                      --prob_error ${ERROR}
                      
./scripts2/gg_map --inp ./testdata/${FNAME}.loc\
                  --out ./testdata/${FNAME}.outloc\
                  --map ./testdata/${FNAME}.outmap\
                  --lg 000\
                  --ga_gibbs_cycles ${CYCLES}\
                  --ga_report 0\
                  --ga_iters ${GA_ITERS}\
                  --gibbs_samples ${SAMPLES}\
                  --gibbs_burnin ${BURNIN}\
                  --gibbs_period ${PERIOD}\
                  --randomise_order 1\
                  --min_prob ${MIN_PROB}
