#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

#verify working directory
RUNDIR=/home/vicker/crosslink/rgxha_map
if [ "${PWD}" != "${RUNDIR}" ]
then
    echo incorrect working directrory
    exit
fi

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_rgxha_old

mkdir -p stats
mkdir -p tmp

rm -f ./stats/all_stats

#for each linkage group
for FNAME in ${OUTDIR}/rgxha_*_1_*.order
do
    PROG=$(echo ${FNAME} | cut -d '_' -f 6 | cut -d '.' -f 1)
    LGNAME=$(echo ${FNAME} | cut -d '_' -f 4)
    LGSIZE=$(cat ${FNAME} | awk '{print $2}' | sort -n | tail -n 1)
    NMARKERS=$(cat ${FNAME} | wc --lines)
    RUNTIME=$(cat ${OUTDIR}/rgxha_${LGNAME}_1_${PROG}_time | awk '{print $2 + $3}')
    echo ${PROG} ${LGNAME} ${LGSIZE} ${NMARKERS} ${RUNTIME} >> ./stats/all_stats
done
