#!/bin/bash

#
# run cross link assuming there is only one linkage groups
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster

set -eu

TESTMAP=$1
PROG=$2

FNAME=${TESTMAP}_${PROG}
LGNAME='000'

#sample one ordering from an optimal ordering
#randomised for ambiguous positions
simulate_optimal.py ${TESTMAP}.map\
                    ${TESTMAP}_orig.loc\
                    2000\
                    > ${FNAME}_simulated.loc

gg_calc_dist --inp ${FNAME}_simulated.loc\
             --out ${FNAME}_${LGNAME}.loc\
             --map ${FNAME}_${LGNAME}.map\
             --lg ${LGNAME}

#get just the marker order and cm posn
tail -n +2 ${FNAME}_${LGNAME}.map\
    | awk '{print $1,$4}'\
    > ${FNAME}.order
