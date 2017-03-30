#!/bin/bash

#Crosslink Copyright (C) 2016  NIAB EMR

#
# extract memory usage stats from SGE log file
#

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/erate_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

elist='0.001 0.005 0.01 0.03 0.06'
rm -f tmpnamelist

for erate in ${elist}
do
    for SAMPLE_DIR in sample_data/${erate}_*
    do
        SAMPLEBASE=$(basename ${SAMPLE_DIR})

        echo mstmap_${SAMPLEBASE}    >> tmpnamelist
        echo lepmap_${SAMPLEBASE}    >> tmpnamelist
        echo tmap_${SAMPLEBASE}      >> tmpnamelist
        echo om_ug_${SAMPLEBASE}     >> tmpnamelist
        echo cl_approx_${SAMPLEBASE} >> tmpnamelist
        echo cl_full_${SAMPLEBASE}   >> tmpnamelist
        echo cl_global_${SAMPLEBASE} >> tmpnamelist
        echo cl_refine_${SAMPLEBASE}   >> tmpnamelist
    done
done

cat /var/lib/gridengine/blacklace/common/accounting | grep -f tmpnamelist | cut -d: -f5,43 > maxvmem_stats

${SCRIPTDIR}/extract_maxvmem.py maxvmem_stats > figs/maxvmem_stats_mod

cat figs/joinmap_stats |
while read line
do
    PROG=$(echo ${line} | cut -d' ' -f1)
    ERATE=$(echo ${line} | cut -d' ' -f2)
    MEM=$(echo ${line} | cut -d' ' -f4)
    echo ${PROG} ${ERATE} ${MEM} >> figs/maxvmem_stats_mod
done
