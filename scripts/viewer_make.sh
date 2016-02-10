#!/bin/bash

#
# build cross linker rflod viewer
# run from laptop with cluster mounted
# because we will run the SDL program on the laptop not direct on the cluster
#

set -eu

#TYPE="-Wall -Wextra -O3"
TYPE="-Wall -Wextra -g"

RJVUTILS=~/rjv_mnt/cluster/git_repos/rjvbio/rjv_cutils.c

gcc ${TYPE}\
    -I/home/vicker/rjv_mnt/cluster/git_repos/rjvbio\
    -I/home/rov/rjv_mnt/cluster/git_repos/rjvbio\
    -o crosslink_viewer\
    gg_utils.c\
    gg_ga.c\
    gg_gibbs.c\
    gg_group.c\
    crosslink_viewer.c\
    crosslink_viewer_main.c\
    ${RJVUTILS}\
    -lSDL2 -lm

gcc ${TYPE}\
    -I/home/vicker/rjv_mnt/cluster/git_repos/rjvbio\
    -I/home/rov/rjv_mnt/cluster/git_repos/rjvbio\
    -o crosslink_graphical\
    gg_utils.c\
    gg_ga.c\
    gg_gibbs.c\
    gg_group.c\
    crosslink_viewer.c\
    crosslink_graphical.c\
    crosslink_graphical_main.c\
    ${RJVUTILS}\
    -lSDL2 -lm
