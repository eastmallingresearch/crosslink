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
            --outbase=${FNAME}_${GROUPLOD}_${MATPATLOD}_\
            --min_lod=${GROUPLOD}\
            --matpat_lod=${MATPATLOD}

GRP_SCORE=$(calc_grouping_accuracy.py ${FNAME}.orig ${FNAME}_${GROUPLOD}_${MATPATLOD}_???.loc)
TYPE_SCORE=$(calc_typeerr_accuracy.py ${FNAME}.orig ${FNAME}_${GROUPLOD}_${MATPATLOD}_???.loc)

echo typeerr001 ${DENSITY} ${MAPSIZE} ${ERATE} ${TYPEERR} ${REP} ${GROUPLOD} ${MATPATLOD} ${GRP_SCORE} ${TYPE_SCORE}\
    > ${STATSDIR}/typeerr001_${DENSITY}_${MAPSIZE}_${ERATE}_${TYPEERR}_${REP}_${GROUPLOD}_${MATPATLOD}
