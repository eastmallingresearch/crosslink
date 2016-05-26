#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# build sdl related scripts
# run from laptop with cluster mounted
# because we will run the SDL program on the laptop not direct on the cluster
#

set -eu

TYPE="-Wall -Wextra -O3"

RJVUTILS=/home/vicker/rjv_mnt/cluster/git_repos/rjvbio/rjv_cutils.c

gcc test_sdl4.c -o test_sdl -lSDL2


#build gg source
#for FNAME in gg_utils gg_ga gg_gibbs gg_group
#do
#    gcc ${TYPE} -c ${FNAME}.c -o ${FNAME}.o
#done

#build gg_group
#gcc ${TYPE}\
#    -o gg_group\
#    gg_group.o\
#    gg_utils.o\
#    gg_group_main.c\
#    ${RJVUTILS}\
#    -lm
