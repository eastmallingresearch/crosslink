#!/bin/bash

#
# create the test maps
# called from 010_crosslink_simdata.sh
#

set -eu

#create map with randomly placed markers
create_map\
        --output-file=${FNAME}.map\
        --numb-lgs=${NLGS}\
        --map-size=${MAPSIZE}\
        --marker-density=${DENSITY}\
        --prob-both=${PROBBOTH}\
        --prob-maternal=${PROBMAT}
           
#simulate genotyping data from the markers
sample_map\
    --input-file=${FNAME}.map\
    --output-file=${FNAME}.loc\
    --orig-file=${FNAME}.orig\
    --samples=${POPSIZE}\
    --prob-missing=${MRATE}\
    --prob-error=${ERATE}\
    --prob-type-error=${TYPEERR}
