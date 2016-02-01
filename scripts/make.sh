#!/bin/bash

#
# build create_map, sample_map and gg_map
# run from the same directory as the source files
#

set -eu

TYPE="-Wall -Wextra -O3 -I/home/vicker/git_repos/rjvbio"

RJVUTILS=/home/vicker/git_repos/rjvbio/rjv_cutils.c

#build create_map
gcc ${TYPE}\
    -o create_map\
    create_map_main.c\
    create_map.c\
    ${RJVUTILS}\
    -lm

#build sample_map
gcc ${TYPE}\
    -o sample_map\
    sample_map_main.c\
    sample_map.c\
    ${RJVUTILS}\
    -lm

#build gg source
for FNAME in gg_utils gg_ga gg_gibbs gg_group
do
    gcc ${TYPE} -c ${FNAME}.c -o ${FNAME}.o
done

#build gg_group
gcc ${TYPE}\
    -o gg_group\
    gg_group.o\
    gg_utils.o\
    gg_group_main.c\
    ${RJVUTILS}\
    -lm
    
#build main executable
gcc ${TYPE}\
    -o gg_map\
    gg_main.c\
    gg_utils.o\
    gg_ga.o\
    gg_group.o\
    gg_gibbs.o\
    ${RJVUTILS}\
    -lm

#build map distance utility
gcc ${TYPE}\
    -o gg_calc_dist\
    gg_calc_dist.c\
    gg_utils.o\
    gg_ga.o\
    gg_group.o\
    gg_gibbs.o\
    ${RJVUTILS}\
    -lm

#build lg fragment sorter utility
gcc ${TYPE}\
    -o crosslink_sorter\
    crosslink_sorter_main.c\
    gg_utils.o\
    ${RJVUTILS}\
    -lm

#build tests
<<COMM
gcc ${TYPE}\
    -o test_ga\
    test_ga.c\
    gg_utils.o\
    gg_ga.o\
    gg_gibbs.o\
    ${RJVUTILS}\
    -lm

gcc ${TYPE}\
    -o test_group\
    gg_group.c\
    test_group.c\
    -lm
COMM
