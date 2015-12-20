#!/bin/bash

#
# run lepmap assuming one lg
#

LM2=/home/vicker/programs/lepmap2/bin
export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

LGFILE=$1
OUTBASE=$2

JAVAOPS="-Xmx512m"
LOD=1.0

java ${JAVAOPS} -cp ${LM2} Filtering\
    data=${LGFILE}.lepmap\
    dataTolerance=0.001\
    > ${OUTBASE}.filtered

java ${JAVAOPS} -cp ${LM2} SeparateChromosomes\
    data=${OUTBASE}.filtered\
    lodLimit=${LOD}\
    > ${OUTBASE}.grouped

java ${JAVAOPS} -cp ${LM2} JoinSingles\
    ${OUTBASE}.grouped\
    data=${OUTBASE}.filtered\
    lodLimit=${LOD}\
    > ${OUTBASE}.joined

java ${JAVAOPS} -cp ${LM2} OrderMarkers\
    map=${OUTBASE}.joined\
    data=${OUTBASE}.filtered\
    > ${OUTBASE}.out

lepmap2map.py ${OUTBASE}.out ${LGFILE}\
    > ${OUTBASE}.order
