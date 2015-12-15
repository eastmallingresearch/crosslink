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

TESTMAP=$1
PROG=$2

FNAME=${TESTMAP}_${PROG}

LOD=1.0

#phase markers
phasing ${TESTMAP}.loc.tmap ${FNAME}.tmap.phased ${LOD} > /dev/null

#order markers
tail -n +3 ${TESTMAP}.loc.tmap\
    | awk '{print $1}'\
    | tmap -b ${FNAME}.tmap.phased\
    > ${FNAME}.tmap.out

#get just the marker order
tail -n +2 ${FNAME}.tmap.out\
    | awk '{print $1,$2}'\
    > ${FNAME}.order
