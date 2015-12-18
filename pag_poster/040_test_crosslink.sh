#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_crosslink

mkdir -p ${OUTDIR}
mkdir -p stats
mkdir -p tmp

for DENSITY in 0.1 1.0 10.0                         #markers per centimorgan
do
    for ERATE in 0.00 0.01 0.05 0.1                 #error/missing rate
    do
        for NMARKERS in 50 100 500 1000 5000 10000  #total markers (one per centimorgan)
        do
            for REP in $(seq 1 40)                  #replicates
            do
                TESTMAP=${OUTDIR}/compare_${ERATE}_${NMARKERS}_${DENSITY}_${REP}
                
                #create test data if not already done
                if [ ! -e ${TESTMAP}.loc ]
                then
                    create_test_map.sh ${TESTMAP} ${ERATE} ${NMARKERS} ${REP} ${DENSITY}
                fi
                
                #test only crosslink
                for PROG in crosslink optimal
                do
                    #if [ -e ${TESTMAP}_${PROG}_stats ]
                    #then
                    #    echo skip
                    #    continue
                    #fi
                
                    while true
                    do
                        NJOBS=$(qstat | wc --lines)
                        echo qstat ${NJOBS}
                        
                        if [ "${NJOBS}" -lt "60" ]
                        then
                            break
                        fi
                        
                        sleep 1
                    done
                
                    if [ ! -e ${TESTMAP}_${PROG}_stats ]
                    then
                        echo myqsub.sh ${SCRIPTDIR}/compare_progs.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                        myqsub.sh ${SCRIPTDIR}/compare_progs.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                    else
                        echo myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                        myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                    fi
                done
            done
        done
    done
done
