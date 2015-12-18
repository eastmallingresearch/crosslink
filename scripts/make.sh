#!/bin/bash

#
# build create_map, sample_map and gg_map
#

set -eu

TYPE="-Wall -Wextra -O3"

#build create_map
gcc ${TYPE}\
    -o ./scripts/create_map\
    ./scripts/create_map_main.c\
    ./scripts/create_map.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

#build sample_map
gcc ${TYPE}\
    -o ./scripts/sample_map\
    ./scripts/sample_map_main.c\
    ./scripts/sample_map.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

#build gg source
for FNAME in gg_utils gg_ga gg_gibbs gg_group
do
    gcc ${TYPE} -c ./scripts/${FNAME}.c -o ./scripts/${FNAME}.o
done

#build gg_group
gcc ${TYPE}\
    -o ./scripts/gg_group\
    ./scripts/gg_group.o\
    ./scripts/gg_utils.o\
    ./scripts/gg_group_main.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm
    
#build main executable
<<COMM
gcc ${TYPE}\
    -o ./scripts/gg_map\
    ./scripts/gg_main.c\
    ./scripts/gg_utils.o\
    ./scripts/gg_ga.o\
    ./scripts/gg_group.o\
    ./scripts/gg_gibbs.o\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm
COMM

#build map distance utility
gcc ${TYPE}\
    -o ./scripts/gg_calc_dist\
    ./scripts/gg_calc_dist.c\
    ./scripts/gg_utils.o\
    ./scripts/gg_ga.o\
    ./scripts/gg_group.o\
    ./scripts/gg_gibbs.o\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

#build tests
<<COMM
gcc ${TYPE}\
    -o ./scripts/test_ga\
    ./scripts/test_ga.c\
    ./scripts/gg_utils.o\
    ./scripts/gg_ga.o\
    ./scripts/gg_gibbs.o\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

gcc ${TYPE}\
    -o ./scripts/test_group\
    ./scripts/gg_group.c\
    ./scripts/test_group.c\
    -lm
COMM
