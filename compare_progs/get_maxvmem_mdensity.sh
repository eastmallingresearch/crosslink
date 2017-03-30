#!/bin/bash

#Crosslink Copyright (C) 2016  NIAB EMR

#
# extract memory usage stats from SGE log file
#

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/mdensity_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

denlist='1 5 10 50 100 150 200'
rm -f tmpnamelist

for den in ${denlist}
do
    for SAMPLE_DIR in sample_data/${den}_*
    do
        SAMPLEBASE=$(basename ${SAMPLE_DIR})

        echo mstmap_${SAMPLEBASE}    >> tmpnamelist
        echo lepmap_${SAMPLEBASE}    >> tmpnamelist
        echo tmap_${SAMPLEBASE}      >> tmpnamelist
        echo om_ug_${SAMPLEBASE}     >> tmpnamelist
        echo cl_approx_${SAMPLEBASE} >> tmpnamelist
        echo cl_full_${SAMPLEBASE}   >> tmpnamelist
        echo cl_global_${SAMPLEBASE} >> tmpnamelist
        echo cl_refine_${SAMPLEBASE} >> tmpnamelist
        echo cl_redun_${SAMPLEBASE}  >> tmpnamelist
    done
done

#exclude cl_global where the runs were killed before finishing
cat tmpnamelist \
| grep -v -e cl_global_50_ -e cl_global_100_ -e cl_global_150_ -e cl_global_200_ \
> tmpnamelist2

cat /var/lib/gridengine/blacklace/common/accounting | grep -f tmpnamelist2 | cut -d: -f5,43 > maxvmem_stats

${SCRIPTDIR}/extract_maxvmem.py maxvmem_stats > figs/maxvmem_stats_mod

cat figs/joinmap_stats |
while read line
do
    PROG=$(echo ${line} | cut -d' ' -f1)
    DENSITY=$(echo ${line} | cut -d' ' -f2)
    MEM=$(echo ${line} | cut -d' ' -f4)
    echo ${PROG} ${DENSITY} ${MEM} >> figs/maxvmem_stats_mod
done
