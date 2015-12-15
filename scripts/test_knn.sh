#!/bin/bash

#
# check hk imputation and map ordering
#

set -u

#FNAME=test_ga_gibbs
FNAME=test
SEED=$1

#create map options
LGS=1
LGSIZE=50
MARKERS=1000
PROB_HK=0.99
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.01
ERROR=0.01
MAPFUNC=1          #1=haldane 2=kosambi

#group options
GRP_RAND_ORDER=1
MIN_LOD=1.0
MIN_LGS=${LGS}
KNN=5

#gg_map options
CYCLES=6
GG_RAND_ORDER=0

#ga options
SKIP_ORDER1=1
GA_ITERS=2000000
OPTIMISE_DIST=0
GA_MST=5
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

#mutations of any size
#PROB_MOVE=0.5
#MAX_MOVESEG=1.0
#MAX_MOVEDIST=1.0
#PROB_INV=0.5
#MAX_SEG=1.0

#gibbs options
SAMPLES=300
BURNIN=10
PERIOD=1
PROB_SEQUENTIAL=0.5
PROB_UNIDIR=0.5
MIN_PROB_1=0.1
MIN_PROB_2=0.0
TWOPT_1=0.5
TWOPT_2=0.0
MIN_CTR=0

rm -f ./testdata/${FNAME}.ga_log ./testdata/${FNAME}.log2 ./testdata/${FNAME}.gibbs_log

echo make
./scripts/make.sh

echo test knn ${FNAME} gg_group

#gdb --args \

./scripts/gg_group --inp ./testdata/${FNAME}.loc\
                    --out ./testdata/${FNAME}.outloc\
                    --map ./testdata/${FNAME}.outmap\
                    --log ./testdata/${FNAME}.log\
                    --prng_seed ${SEED}\
                    --map_func ${MAPFUNC}\
                    --randomise_order ${GRP_RAND_ORDER}\
                    --check_phase 1\
                    --bitstrings 1\
                    --show_pearson 1\
                    --min_lgs ${MIN_LGS}\
                    --min_lod ${MIN_LOD}\
                    --knn ${KNN}
                    #> ./testdata/${FNAME}.tmpmap

cat ./testdata/${FNAME}.origloc | grep '^m' | sort > ./testdata/${FNAME}.imploc1   #no errors or missing
cat ./testdata/${FNAME}.loc     | grep '^m' | sort > ./testdata/${FNAME}.imploc2   #with missing and errors
cat ./testdata/${FNAME}.outloc  | grep '^m' | sort > ./testdata/${FNAME}.imploc3   #missing imputed

echo check imputing ${FNAME}
./scripts/check_imputing.py ./testdata/${FNAME}.imploc1\
                             ./testdata/${FNAME}.imploc2\
                             ./testdata/${FNAME}.imploc3
                             #> /dev/null
