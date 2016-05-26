#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# gg_group
#

set -u

FNAME=test_group
SEED=$1

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
MAPFUNC=1

#group options
MIN_LOD=3.0
MIN_LGS=${LGS}

echo make
./scripts2/make.sh

echo create_map
./scripts2/create_map --out ./testdata/${FNAME}.map\
                      --nmarkers ${MARKERS}\
                      --nlgs ${LGS}\
                      --prng_seed ${SEED}\
                      --lg_size ${LGSIZE}\
                      --prob_hk ${PROB_HK}\
                      --prob_lm ${PROB_LM}

echo sample_map
./scripts2/sample_map --inp ./testdata/${FNAME}.map\
                      --out ./testdata/${FNAME}.loc\
                      --nind ${POPSIZE}\
                      --prng_seed ${SEED}\
                      --prob_missing ${MISSING}\
                      --prob_error ${ERROR}\
                      --map_func ${MAPFUNC}

echo gg_group
#gdb --args \

./scripts2/gg_group --inp ./testdata/${FNAME}.loc\
                    --out ./testdata/${FNAME}.outloc\
                    --log ./testdata/${FNAME}.log\
                    --prng_seed ${SEED}\
                    --check_phase 1\
                    --show_pearson 1\
                    --min_lgs ${MIN_LGS}\
                    --min_lod ${MIN_LOD}

cat ./testdata/${FNAME}.loc | grep '^m0' | sort > ./testdata/${FNAME}.loc.sort
cat ./testdata/${FNAME}.outloc | grep '^m0' | sort > ./testdata/${FNAME}.outloc.sort
