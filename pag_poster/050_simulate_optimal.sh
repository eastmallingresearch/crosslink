#!/bin/bash

#
# for each test map, simulate sampling orderings from an
# optimal mapping program
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster
OUTDIR=compare_crosslink
PROG=optimal

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
                    echo ${TESTMAP}.loc does not exist
                    exit
                fi
            
                while true
                do
                    NJOBS=$(qstat | wc --lines)
                    echo ${NJOBS}
                    
                    if [ "${NJOBS}" -lt "45" ]
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
