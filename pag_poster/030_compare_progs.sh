#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_progs
DENSITY=10.0                          #markers per centimorgan

mkdir -p ${OUTDIR}
mkdir -p stats
mkdir -p tmp

for ERATE in 0.00 0.01 0.05 0.1      #error/missing rate
do
    for NMARKERS in 20 60 100  #total markers (one per centimorgan)
    do
        for REP in $(seq 1 40)       #replicates
        do
            TESTMAP=${OUTDIR}/compare_${ERATE}_${NMARKERS}_${DENSITY}_${REP}
            
            #create test data if not already done
            if [ ! -e ${TESTMAP}.loc ]
            then
                create_test_map.sh ${TESTMAP} ${ERATE} ${NMARKERS} ${REP} ${DENSITY}
            fi
        
            #test each program
            for PROG in crosslink lepmap onemap tmap
            do
                while true
                do
                    NJOBS=$(qstat | wc --lines)
                    echo ${NJOBS}
                    
                    if [ "${NJOBS}" -lt "100" ]
                    then
                        break
                    fi
                    sleep 1
                done
            
                if [ ! -e ${TESTMAP}_${PROG}_stats ]
                then
                    myqsub.sh ${SCRIPTDIR}/compare_progs.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                fi
            done
        done
    done
done
