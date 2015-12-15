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
run_onemap1_small.R\
    ${INPNAME}.onemap\
    ${OUTDIR}/${FNAME}.onemap1.out

#get just the marker order
tail -n +2 ${OUTDIR}/${FNAME}.onemap1.out\
    | awk '{print $2,$3}'\
    > ${OUTDIR}/${FNAME}.order
