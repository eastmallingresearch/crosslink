#!/bin/bash

#
# build create_map, sample_map and gg_map
# run from the same directory as the source files
#

set -eu

TYPE="-Wall -Wextra -Wno-missing-field-initializers -Wno-missing-braces -O3"

#build create_map
gcc ${TYPE}\
    -o create_map\
    create_map_main.c\
    create_map.c\
    -lm

#build sample_map
gcc ${TYPE}\
    -o sample_map\
    sample_map_main.c\
    sample_map.c\
    -lm

#build gg source
for FNAME in crosslink_utils crosslink_ga crosslink_gibbs crosslink_group rjv_cutils
do
    gcc ${TYPE} -c ${FNAME}.c -o ${FNAME}.o
done

#build gg_group
gcc ${TYPE}\
    -o crosslink_group\
    crosslink_group.o\
    crosslink_utils.o\
    rjv_cutils.o\
    crosslink_group_main.c\
    -lm
    
#build main executable
gcc ${TYPE}\
    -o crosslink_map\
    crosslink_map_main.c\
    crosslink_utils.o\
    crosslink_ga.o\
    crosslink_group.o\
    crosslink_gibbs.o\
    rjv_cutils.o\
    -lm
