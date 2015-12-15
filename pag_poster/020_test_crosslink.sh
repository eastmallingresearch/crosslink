#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

mkdir -p stats
mkdir -p tmp

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=crosslinkonly_data

mkdir -p ${OUTDIR}

#for each replicate
for ERATE in 0.00 0.01 0.05 0.1
do
    for NMARKERS in 50 100 500 1000 5000 10000
    do
        for REP in $(seq 21 40)
        do
            myqsub.sh ${SCRIPTDIR}/test_crosslink_only.sge ${ERATE} ${NMARKERS} ${REP}
        done
    done
done
