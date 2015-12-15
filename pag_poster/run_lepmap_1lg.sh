#!/bin/bash

#
# run lepmap assuming one lg
#

LM2=/home/vicker/programs/lepmap2/bin
export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

TESTMAP=$1
PROG=$2

FNAME=${TESTMAP}_${PROG}
JAVAOPS="-Xmx512m"
LOD=1.0

java ${JAVAOPS} -cp ${LM2} Filtering\
    data=${TESTMAP}.loc.lepmap\
    dataTolerance=0.001\
    > ${FNAME}.filtered

java ${JAVAOPS} -cp ${LM2} SeparateChromosomes\
    data=${FNAME}.filtered\
    lodLimit=${LOD}\
    > ${FNAME}.grouped

java ${JAVAOPS} -cp ${LM2} JoinSingles\
    ${FNAME}.grouped\
    data=${FNAME}.filtered\
    lodLimit=${LOD}\
    > ${FNAME}.joined

java ${JAVAOPS} -cp ${LM2} OrderMarkers\
    map=${FNAME}.joined\
    data=${FNAME}.filtered\
    > ${FNAME}.out

lepmap2map.py ${FNAME}.out ${TESTMAP}.loc\
    > ${FNAME}.order
