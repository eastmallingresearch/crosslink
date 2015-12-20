#!/bin/bash

#
# run tmap assuming there is only one linkage groups
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/scripts
export PATH=${PATH}:/home/rov/rjv_mnt/cluster/git_repos/crosslink/pag_poster
export PATH=/home/vicker/programs/tmap:${PATH}

set -eu

LGFILE=$1
OUTBASE=$2

LOD=1.0

#phase markers
phasing ${LGFILE}.tmap ${OUTBASE}.phased ${LOD}

#order markers
tail -n +3 ${LGFILE}.tmap\
    | awk '{print $1}'\
    | tmap -b ${OUTBASE}.phased\
    > ${OUTBASE}.out

#get just the marker order
tail -n +2 ${OUTBASE}.out\
    | awk '{print $1,$2}'\
    > ${OUTBASE}.order
