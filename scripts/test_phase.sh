#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# test gg_phase
#

set -u

FNAME=test_phase
SEED=$1

#create map options
LGS=1
LGSIZE=0.1
MARKERS=1000
PROB_HK=1.0
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.0
ERROR=0.0
MAPFUNC=1

#group options
MIN_LOD=20.0
MIN_LGS=${LGS}

#phase options
MIN_LOD2=20.0

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
./scripts2/gg_group --inp ./testdata/${FNAME}.loc\
                    --out ./testdata/${FNAME}.outloc\
                    --log ./testdata/${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lgs ${MIN_LGS}\
                    --min_lod ${MIN_LOD}
                    
echo gg_phase
./scripts2/gg_phase --inp ./testdata/${FNAME}.outloc\
                    --out ./testdata/${FNAME}.outloc2\
                    --log ./testdata/${FNAME}.log2\
                    --lg 000\
                    --prng_seed ${SEED}\
                    --min_lod ${MIN_LOD2}\
                    --check_phase 1

cat ./testdata/${FNAME}.loc      | grep '^m0' | sort > ./testdata/${FNAME}.sort0
cat ./testdata/${FNAME}.outloc2  | grep '^m0' | sort > ./testdata/${FNAME}.sort1
