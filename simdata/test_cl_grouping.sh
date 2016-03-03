#!/bin/bash

#
# quantify grouping accuracy with current parameters
# called from 010_crosslink_simdata.sh
#

set -eu

crosslink_group\
            --inp=${FNAME}.loc\
            --outbase=${FNAME}_${GROUPLOD}_\
            --min_lod=${GROUPLOD}

SCORE=$(calc_grouping_accuracy.py ${FNAME}.orig ${FNAME}_${GROUPLOD}_???.loc)

echo ${BASENAME} ${DENSITY} ${MAPSIZE} ${ERATE} ${MRATE} ${REP} ${GROUPLOD} ${SCORE}\
    > ${STATSDIR}/${BASENAME}_${DENSITY}_${MAPSIZE}_${ERATE}_${MRATE}_${REP}_${GROUPLOD}
