#!/bin/bash

#
# run onemap assuming there is only one linkage groups
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

TESTMAP=$1
PROG=$2

FNAME=${TESTMAP}_${PROG}

run_onemap_1lg.R ${TESTMAP}.loc.onemap ${FNAME}.out

#get just the marker order
tail -n +2 ${FNAME}.out\
    | awk '{print $2,$3}'\
    > ${FNAME}.order
