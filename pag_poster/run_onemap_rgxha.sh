#!/bin/bash

#
# run onemap assuming there is only one linkage groups
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

LGFILE=$1
OUTBASE=$2

run_onemap_1lg.R ${LGFILE}.onemap ${OUTBASE}.out

#get just the marker order
tail -n +2 ${OUTBASE}.out\
    | awk '{print $2,$3}'\
    > ${OUTBASE}.order
