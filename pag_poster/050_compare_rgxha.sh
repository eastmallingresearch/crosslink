#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_rgxha

mkdir -p ${OUTDIR}
mkdir -p stats
mkdir -p tmp

#for each linkage group
for LGFILE in ./new_map/RGxHA_grouped_*.loc
do
    LGNAME=${LGFILE/\.\/new_map\/RGxHA_grouped_/}
    LGNAME=${LGNAME/\.loc/}

    #replicates
    for REP in $(seq 1 10)       
    do
        #test each program
        for PROG in crosslink #lepmap onemap tmap
        do
            OUTBASE=${OUTDIR}/rgxha_${LGNAME}_${REP}_${PROG}
        
            while true
            do
                NJOBS=$(qstat | wc --lines)
                echo ${NJOBS}
                
                if [ "${NJOBS}" -lt "128" ]
                then
                    break
                fi
                
                sleep 1
            done
        
            if [ ! -e ${OUTBASE}_stats ]
            then
                #run mapping program
                echo myqsub.sh ${SCRIPTDIR}/compare_rgxha.sge ${LGFILE} ${OUTBASE} ${PROG}
                myqsub.sh ${SCRIPTDIR}/compare_rgxha.sge ${LGFILE} ${OUTBASE} ${PROG}
            #else
                #recalculate stats
                #echo myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                #myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
            fi
        done
    done
done
