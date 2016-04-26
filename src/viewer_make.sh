#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# build crosslink_viewer and crosslink_graphical
#

set -eu

TYPE="-Wall -Wextra -O3"
#TYPE="-Wall -Wextra -g"

#select alternative colour scheme
AUX=""
#AUX="-DALTCOLSCHEME"

mkdir -p ../bin

gcc ${TYPE} ${AUX}\
    -o ../bin/crosslink_viewer\
    crosslink_utils.c\
    crosslink_ga.c\
    crosslink_gibbs.c\
    crosslink_group.c\
    crosslink_viewer.c\
    crosslink_viewer_main.c\
    rjvparser.c\
    -lSDL2 -lSDL2_image -lm

gcc ${TYPE} ${AUX}\
    -o ../bin/crosslink_graphical\
    crosslink_utils.c\
    crosslink_ga.c\
    crosslink_gibbs.c\
    crosslink_group.c\
    crosslink_viewer.c\
    crosslink_graphical.c\
    crosslink_graphical_main.c\
    rjvparser.c\
    -lSDL2 -lSDL2_image -lm
