#!/bin/bash

#Crosslink, Copyright (C) 2016  NIAB EMR

#
# run lepmap assuming one lg
#

LM2=/home/vicker/programs/lepmap2/bin

set -eu

JAVAOPS="-Xmx512m"
LOD=1.0

java ${JAVAOPS} -cp ${LM2} Filtering\
    data=${FILEBASE}.lepmap\
    dataTolerance=0.001\
    > sample.filtered

java ${JAVAOPS} -cp ${LM2} SeparateChromosomes\
    data=sample.filtered\
    lodLimit=${LOD}\
    > sample.grouped

java ${JAVAOPS} -cp ${LM2} JoinSingles\
    sample.grouped\
    data=sample.filtered\
    lodLimit=${LOD}\
    > sample.joined

java ${JAVAOPS} -cp ${LM2} OrderMarkers\
    map=sample.joined\
    data=sample.filtered\
    > sample.out

