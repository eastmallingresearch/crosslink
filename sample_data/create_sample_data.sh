#!/bin/bash

#
# create a sample data set
#

set -eu

#change this to point towards the crosslink directory containing create_map and sample_map
CROSSLINK_PATH=~/git_repos/crosslink/scripts


export PATH=${CROSSLINK_PATH}:${PATH}

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

create_map --output-file=${FNAME}.map\
           --numb-lgs=${NUMB_LGS}\
           --map-size=${MAP_SIZE}\
           --marker-density=${MARKER_DENSITY}\
           --prob-both=${PROB_HK}\
           --prob-maternal=${PROB_LM}\
           --random-seed=${SEED}
           
#simulate genotyping data from the map
#population size 200 F1 offspring
#average of 1% missing data, 1% genotyping error, no marker typing errors
POP_SIZE=200
PROB_MISSING=0.01
PROB_ERROR=0.01
PROB_TYPE_ERR=0.0

sample_map --input-file=${FNAME}.map\
           --output-file=${FNAME}.loc\
           --orig-file=${FNAME}_orig.loc\
           --samples=${POP_SIZE}\
           --prob-missing=${PROB_MISSING}\
           --prob-error=${PROB_ERROR}\
           --prob-type-err=${PROB_TYPE_ERR}\
           --random-seed=${SEED}
