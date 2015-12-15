#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/vicker/programs/tmap

mkdir -p stats

#test on a small map: 1 LG, 50 centimorgan, 30 markers
rm -f stats/smallmap_tmap.csv
for SEED in $(seq 1 40)
do
    START_SECS=$SECONDS
    SCORE=$(test_tmap_small.sh ${SEED})
    TOTAL_SECS=$(($SECONDS - $START_SECS))
    echo ${SCORE} ${TOTAL_SECS}
done >> stats/smallmap_tmap.csv
