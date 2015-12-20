#!/bin/bash

#
# test crosslink on simulated data
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

mkdir -p ${OUTDIR}
mkdir -p stats
mkdir -p tmp

#for each linkage group
for LGFILE in ./prev_map/RGxHA_grouped_*.loc
do
    LGNAME=${LGFILE/\.\/prev_map\/RGxHA_grouped_/}
    LGNAME=${LGNAME/\.loc/}
    
    #convert to other formats
    if [ ! -e "${LGFILE}.tmap" ]
    then
        NMARKERS=$(tail -n +5 ${LGFILE} | wc --lines)
        NSAMPLES=$(tail -n +5 ${LGFILE} | head -n 1 | awk '{print NF-3}')
    
        #convert to tmap format
        echo "data type outbred"                 >  ${LGFILE}.tmap
        echo "${NSAMPLES} ${NMARKERS}"           >> ${LGFILE}.tmap
        tail -n +5 ${LGFILE}\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'               >> ${LGFILE}.tmap
            
        #convert to lepmap format
        convert2lepmap.py ${LGFILE}             >  ${LGFILE}.lepmap.tmp
        transpose_tsv.py ${LGFILE}.lepmap.tmp   >  ${LGFILE}.lepmap

        #convert to onemap format
        convert2onemap.py ${LGFILE}             >  ${LGFILE}.onemap
    fi

    #replicates
    for REP in $(seq 1 1)
    do
        #test each program
        for PROG in lepmap crosslink lepmap onemap tmap
        do
            OUTBASE=${OUTDIR}/rgxha_${LGNAME}_${REP}_${PROG}
        
            while true
            do
                NJOBS=$(qstat | wc --lines)
                echo ${NJOBS}
                
                if [ "${NJOBS}" -lt "150" ]
                then
                    break
                fi
                
                sleep 1
            done
        
            #if [ ! -e ${OUTBASE}_stats ]
            #then
                #run mapping program
                echo myqsub.sh ${SCRIPTDIR}/compare_rgxha.sge ${LGFILE} ${OUTBASE} ${PROG}
                myqsub.sh ${SCRIPTDIR}/compare_rgxha.sge ${LGFILE} ${OUTBASE} ${PROG}
            #else
                #recalculate stats
                #echo myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
                #myqsub.sh ${SCRIPTDIR}/compare_progs_recalc_stats.sge ${OUTDIR} ${TESTMAP} ${ERATE} ${NMARKERS} ${PROG} ${REP} ${DENSITY}
            #fi
        done
    done
done
