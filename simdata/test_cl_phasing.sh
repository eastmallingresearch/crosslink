#!/bin/bash

#$ -S /bin/bash
#$ -l h_vmem=1.0G
#$ -l mem_free=1.0G
#$ -l virtual_free=1.0G
#$ -l h_rt=999:00:00

#
# quantify grouping accuracy with current parameters
# called from 010_crosslink_simdata.sh
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/simdata

set -eu

crosslink_group\
            --inp=${FNAME}.loc\
            --outbase=${FNAME}_${GROUPLOD}_\
            --min_lod=${GROUPLOD}

GRP_SCORE=$(calc_grouping_accuracy.py ${FNAME}.orig ${FNAME}_${GROUPLOD}_???.loc)
PHASING_SCORE=$(calc_phasing_accuracy.py ${FNAME}.orig ${FNAME}_${GROUPLOD}_???.loc)

echo phasing001 ${DENSITY} ${MAPSIZE} ${ERATE} ${REP} ${GROUPLOD} ${GRP_SCORE} ${PHASING_SCORE}\
    > ${STATSDIR}/phasing001_${DENSITY}_${MAPSIZE}_${ERATE}_${REP}_${GROUPLOD}
