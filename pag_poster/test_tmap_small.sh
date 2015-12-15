#!/bin/bash

#
# test tmap on simulated data
# small map, 1 LG
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster
export PATH=/home/vicker/programs/tmap:${PATH}

set -eu

INPNAME=$1
FNAME=$(basename ${INPNAME/.loc/})
OUTDIR=$2

mkdir -p ${OUTDIR}


RUN_PHASE=1
RUN_TMAP=1

LGNAME=000

if [ "${RUN_PHASE}" == "1" ]
then
    #phase markers
    phasing ${INPNAME}.tmap ${OUTDIR}/${FNAME}.tmap.phased > /dev/null
fi

if [ "${RUN_TMAP}" == "1" ]
then
    #order markers
    tail -n +3 ${INPNAME}.tmap\
        | awk '{print $1}'\
        | tmap -b ${OUTDIR}/${FNAME}.tmap.phased\
        > ${OUTDIR}/${FNAME}.tmap.out

    #get just the marker order
    tail -n +2 ${OUTDIR}/${FNAME}.tmap.out\
        | awk '{print $1,$2}'\
        > ${OUTDIR}/${FNAME}.order
fi

