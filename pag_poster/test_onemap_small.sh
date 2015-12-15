#!/bin/bash

#
# test onemap on simulated data
# small map, 1 LG
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster

set -eu

INPNAME=$1
FNAME=$(basename ${INPNAME/.loc/})
OUTDIR=$2

mkdir -p ${OUTDIR}

#phase markers
run_onemap_small.R ${INPNAME}.onemap ${OUTDIR}/${FNAME}.onemap.out

#order markers
#tail -n +3 ${INPNAME}.tmap\
#    | awk '{print $1}'\
#    | tmap -b ${OUTDIR}/${FNAME}.tmap.phased\
#    > ${OUTDIR}/${FNAME}.tmap.out

#get just the marker order
#tail -n +2 ${OUTDIR}/${FNAME}.tmap.out\
#    | awk '{print $1}'\
#    > ${OUTDIR}/${FNAME}.order

