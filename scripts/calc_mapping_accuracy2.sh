#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# calculate mapping accuracy:
# find which linkage group best matches each reference linkage group
# find the correlation coefficient between map positions between the two
# weighted by the proportion of reference markers that are in the evaluated group
#
# usage example: calc_mapping_accuracy2.sh refmap.spec test.csv

set -eu

CL_REF_MAP=$1
CL_EVAL_MAP=$2

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#convert reference map spec into csv format: marker_name,linkage_group,centimorgan_position
cat ${CL_REF_MAP} | grep -v -e '^#' | awk -v OFS=',' '{print $1,$4,$5}'\
    > ${MYTMPDIR}/refmap.csv

#match lgs to reference map
mapping_accuracy.py ${MYTMPDIR}/refmap.csv ${CL_EVAL_MAP}

rm -rf ${MYTMPDIR}
