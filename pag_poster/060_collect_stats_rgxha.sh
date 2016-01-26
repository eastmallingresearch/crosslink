#!/bin/bash

#
# test all mapping programs on RGxHA lgs
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

#verify working directory
RUNDIR=/home/vicker/crosslink/rgxha_map
if [ "${PWD}" != "${RUNDIR}" ]
then
    echo incorrect working directrory
    exit
fi

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_rgxha_old

mkdir -p stats
mkdir -p tmp

rm -f ./stats/all_stats
rm -f ./stats/all_compare

#for each linkage group, collect basic stats
for FNAME in ${OUTDIR}/rgxha_*_1_*.order
do
    PROG=$(echo ${FNAME} | cut -d '_' -f 6 | cut -d '.' -f 1)
    LGNAME=$(echo ${FNAME} | cut -d '_' -f 4)
    LGSIZE=$(cat ${FNAME} | awk '{print $2}' | sort -n | tail -n 1)
    NMARKERS=$(cat ${FNAME} | wc --lines)
    RUNTIME=$(cat ${OUTDIR}/rgxha_${LGNAME}_1_${PROG}_time | awk '{print $2 + $3}')
    echo ${PROG} ${LGNAME} ${LGSIZE} ${NMARKERS} ${RUNTIME} >> ./stats/all_stats
done

#compare ordering between programs
for PROGNAMES in crosslink_tmap crosslink_onemap crosslink_lepmap tmap_onemap tmap_lepmap onemap_lepmap
do
    PROG1=$(echo ${PROGNAMES} | cut -d '_' -f 1)
    PROG2=$(echo ${PROGNAMES} | cut -d '_' -f 2)
    echo ${PROG1} ${PROG2}
    
    for LGNUMB in 1 2 3 4 5 6 7
    do
        for LGLETTER in A B C D E F G
        do
            FILE1=${OUTDIR}/rgxha_${LGNUMB}${LGLETTER}_1_${PROG1}.order
            FILE2=${OUTDIR}/rgxha_${LGNUMB}${LGLETTER}_1_${PROG2}.order
            
            if [ ! -e "${FILE1}" ] || [ ! -e "${FILE2}" ]
            then
                continue
            fi
            
            echo -n "${PROG1}_${PROG2} "                      >> ./stats/all_compare
            ${SCRIPTDIR}/calc_spearmans2.py ${FILE1} ${FILE2} >> ./stats/all_compare
        done
    done
done
