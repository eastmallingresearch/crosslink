#!/bin/bash

#
# create a sample data set
#

set -eu

#change this to point towards the crosslink directory containing create_map and sample_map
export PATH=~/git_repos/crosslink/scripts:${PATH}

#500 cM map with an average of 1 marker per centimorgan
#divided into ten linkage groups of equal size
FNAME=test01

#using the same seed should guarantee getting exactly the same results
#provided no other parameters are changed
#use a value of 0 to seed from system time
SEED=1

MAP_SIZE=500
MARKER_DENSITY=1.0
NUMB_LGS=10
PROB_HK=0.333
PROB_LM=0.5

create_map --out ${FNAME}.map\
           --nlgs ${NUMB_LGS}\
           --map_size ${MAP_SIZE}\
           --density ${MARKER_DENSITY}\
           --prob_hk ${PROB_HK}\
           --prob_lm ${PROB_LM}\
           --prng_seed ${SEED}
           
#simulate genotyping data from the map
#population size 200 F1 offspring
#average of 1% missing data, 1% genotyping error, no marker typing errors
POP_SIZE=200
PROB_MISSING=0.01
PROB_ERROR=0.01
PROB_TYPE_ERR=0.0

sample_map --inp ${FNAME}.map\
           --out ${FNAME}.loc\
           --orig ${FNAME}_orig.loc\
           --nind ${POP_SIZE}\
           --prob_missing ${PROB_MISSING}\
           --prob_error ${PROB_ERROR}\
           --prob_type_err ${PROB_TYPE_ERR}\
           --prng_seed ${SEED}
