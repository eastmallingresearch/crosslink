#!/bin/bash

#
# build create_map, sample_map and gg_map
# run from the same directory as the source files
#

set -eu

if [ "$(hostname)" == "enterprise" ]
then
    TYPE="-Wall -Wextra -O3 -I/home/vicker/rjv_mnt/cluster/git_repos/rjvbio"
    RJVUTILS=/home/vicker/rjv_mnt/cluster/git_repos/rjvbio/rjv_cutils.c
else
    TYPE="-Wall -Wextra -O3 -I/home/vicker/git_repos/rjvbio"
    RJVUTILS=/home/vicker/git_repos/rjvbio/rjv_cutils.c
fi

#build gg source
for FNAME in crosslink_utils crosslink_ga crosslink_gibbs crosslink_group
do
    gcc ${TYPE} -c ${FNAME}.c -o ${FNAME}.o
done

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

#build gg_group
gcc ${TYPE}\
    -o crosslink_group\
    crosslink_group.o\
    crosslink_utils.o\
    crosslink_group_main.c\
    ${RJVUTILS}\
    -lm
    
#build main executable
gcc ${TYPE}\
    -o crosslink_map\
    crosslink_map_main.c\
    crosslink_utils.o\
    crosslink_ga.o\
    crosslink_group.o\
    crosslink_gibbs.o\
    ${RJVUTILS}\
    -lm

#build map distance utility
gcc ${TYPE}\
    -o crosslink_calc_dist\
    crosslink_calc_dist.c\
    crosslink_utils.o\
    crosslink_ga.o\
    crosslink_group.o\
    crosslink_gibbs.o\
    ${RJVUTILS}\
    -lm

#build lg fragment sorter utility
gcc ${TYPE}\
    -o crosslink_sorter\
    crosslink_sorter_main.c\
    crosslink_utils.o\
    ${RJVUTILS}\
    -lm
