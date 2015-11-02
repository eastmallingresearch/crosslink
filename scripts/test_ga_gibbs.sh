#!/bin/bash

#
# check hk imputation and map ordering
#

set -u

FNAME=test_ga_gibbs
#FNAME=test
SEED=$1

#create map options
LGS=1
LGSIZE=50
MARKERS=1000
PROB_HK=0.333
PROB_LM=0.5

#sample map options
POPSIZE=200
MISSING=0.01
ERROR=0.01
MAPFUNC=1          #1=haldane 2=kosambi

#group options
GRP_RAND_ORDER=1
MIN_LOD=3.0
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
                      --orig ./testdata/${FNAME}.origloc\
                      --nind ${POPSIZE}\
                      --prng_seed ${SEED}\
                      --prob_missing ${MISSING}\
                      --prob_error ${ERROR}\
                      --map_func ${MAPFUNC}

echo joinmap export
#hide information so joinmap cannot "cheat"
head -n 5 ./testdata/${FNAME}.loc > ./testdata/${FNAME}_joinmap.loc
tail -n +6 ./testdata/${FNAME}.loc\
    | sed 's/ {..}//g'\
    | sed 's/kh/hk/g'\
    | sort -R\
    | ./scripts2/reverse_marker_posn.py\
    >> ./testdata/${FNAME}_joinmap.loc

echo gg_group
./scripts2/gg_group --inp ./testdata/${FNAME}.loc\
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

cat ./testdata/${FNAME}.origloc | grep '^m0' | sort > ./testdata/${FNAME}.imploc1   #no errors or missing
cat ./testdata/${FNAME}.loc     | grep '^m0' | sort > ./testdata/${FNAME}.imploc2   #with missing and errors
cat ./testdata/${FNAME}.outloc  | grep '^m0' | sort > ./testdata/${FNAME}.imploc3   #missing imputed

./scripts2/check_imputing.py ./testdata/${FNAME}.imploc1\
                             ./testdata/${FNAME}.imploc2\
                             ./testdata/${FNAME}.imploc3
                             #> /dev/null

cat ./testdata/${FNAME}.log

echo gg_map

#gdb --args

<<COMM
./scripts2/gg_map --inp ./testdata/${FNAME}.outloc\
                  --out ./testdata/${FNAME}.outloc2\
                  --log ./testdata/${FNAME}.log2\
                  --map ./testdata/${FNAME}.outmap2\
                  --mstmap ./testdata/${FNAME}.mstmap\
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
COMM
        
#cat ./testdata/${FNAME}.log2 | grep -e 'final number of hk errors' -e 'final pearson' -e 'still set to missing'
#cat ./testdata/${FNAME}.log2 | awk 'NF==3{print}' > ./testdata/${FNAME}.ga_log
#cat ./testdata/${FNAME}.log2 | awk 'NF==4{print}' > ./testdata/${FNAME}.gibbs_log

#cat ./testdata/${FNAME}.outloc | grep '^m0' | awk '{print substr($1,6)}' > ./testdata/${FNAME}.cmploc
#tail -n +2 ./testdata/${FNAME}.outmap | awk '{print substr($1,6),$4}' > ./testdata/${FNAME}.cmpmap
#cat ./testdata/${FNAME}.outmap2 | grep '^m0' | awk '{print $1,$4}' > ./testdata/${FNAME}.outmap3


#./scripts2/check_map_order.py --inp ./testdata/test_ga_gibbs.outmap --maptype map
#./scripts2/check_map_order.py --inp ./testdata/test_ga_gibbs.outmap2 --maptype map
#./scripts2/check_map_order.py --inp ./testdata/test_ga_gibbs.mstmap2 --maptype map

#convert joinmap map file into more compact form and unreverse marker names
<<COMM
FNAME=test_ga_gibbs
cat ./testdata/${FNAME}_joinmap.map \
    | awk 'length($0)>2{print}' \
    | tail -n +3 \
    | ./scripts2/reverse_marker_posn.py\
    > ./testdata/${FNAME}_joinmap.map2
COMM
#./scripts2/check_map_order.py --inp ./testdata/test_ga_gibbs_joinmap.map2 --maptype map2
