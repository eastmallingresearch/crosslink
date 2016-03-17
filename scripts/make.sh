#!/bin/bash

#
# build create_map, sample_map, crosslink_group and crosslink_map
# run from the same directory as the source files
#

set -eu

TYPE="-Wall -Wextra -O3"
#TYPE="-Wall -Wextra -g"

#build shared source files
for FNAME in crosslink_utils crosslink_ga crosslink_gibbs crosslink_group rjvparser
do
    gcc ${TYPE} -c ${FNAME}.c -o ${FNAME}.o
done

#build create_map
gcc ${TYPE}\
    -o create_map\
    create_map_main.c\
    create_map.c\
    rjvparser.o\
    -lm

#build sample_map
gcc ${TYPE}\
    -o sample_map\
    sample_map_main.c\
    sample_map.c\
    rjvparser.o\
    -lm

#build crosslink_map
gcc ${TYPE}\
    -o crosslink_map\
    crosslink_map_main.c\
    crosslink_utils.o\
    crosslink_ga.o\
    crosslink_group.o\
    crosslink_gibbs.o\
    rjvparser.o\
    -lm

#build crosslink_pos
gcc ${TYPE}\
    -o crosslink_pos\
    crosslink_pos_main.c\
    crosslink_utils.o\
    crosslink_ga.o\
    crosslink_group.o\
    crosslink_gibbs.o\
    rjvparser.o\
    -lm
    
#build crosslink_group
gcc ${TYPE}\
    -o crosslink_group\
    crosslink_group.o\
    crosslink_utils.o\
    rjvparser.o\
    crosslink_group_main.c\
    -lm
