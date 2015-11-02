#!/bin/bash

#
# build create_map, sample_map and gg_map
#

set -eu

TYPE="-Wall -Wextra -g"

#build create_map
<<COMM
gcc ${TYPE}\
    -o ./scripts2/create_map\
    ./scripts2/create_map_main.c\
    ./scripts2/create_map.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm
COMM

#build sample_map
gcc ${TYPE}\
    -o ./scripts2/sample_map\
    ./scripts2/sample_map_main.c\
    ./scripts2/sample_map.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

#build gg source
for FNAME in gg_utils gg_ga gg_gibbs gg_group
do
    gcc ${TYPE} -c ./scripts2/${FNAME}.c -o ./scripts2/${FNAME}.o
done

#build gg_group
gcc ${TYPE}\
    -o ./scripts2/gg_group\
    ./scripts2/gg_group.o\
    ./scripts2/gg_utils.o\
    ./scripts2/gg_group_main.c\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

    
#build main executable
gcc ${TYPE}\
    -o ./scripts2/gg_map\
    ./scripts2/gg_main.c\
    ./scripts2/gg_utils.o\
    ./scripts2/gg_ga.o\
    ./scripts2/gg_group.o\
    ./scripts2/gg_gibbs.o\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

#build tests
<<COMM
gcc ${TYPE}\
    -o ./scripts2/test_ga\
    ./scripts2/test_ga.c\
    ./scripts2/gg_utils.o\
    ./scripts2/gg_ga.o\
    ./scripts2/gg_gibbs.o\
    /home/vicker/git_repos/rjvbio/rjv_cutils.c\
    -lm

gcc ${TYPE}\
    -o ./scripts2/test_group\
    ./scripts2/gg_group.c\
    ./scripts2/test_group.c\
    -lm
COMM
