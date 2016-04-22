#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# calculate mapping accuracy:
# find which linkage group best matches each reference linkage group
# find the correlation coefficient between map positions between the two
# weighted by the proportion of reference markers that are in the evaluated group
#
# usage example: calc_mapping_accuracy.sh refmap.map 'testmap/*.map'

set -eu

CL_REF_MAP=$1
CL_EVAL_MAPS=$2        #protect this argument with single quotes if it contains a wildcard

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#convert reference map into csv format: marker_name,linkage_group,centimorgan_position
cat ${CL_REF_MAP} | grep -v -e '^#' | awk -v OFS=',' '{print $1,$4,$5}'\
    > ${MYTMPDIR}/refmap.csv

#extract one map position per marker, combined if available otherwise maternal or paternal
make_combined_map.py ${CL_EVAL_MAPS}\
    > ${MYTMPDIR}/evalmap.csv

#match lgs to reference map
mapping_accuracy.py ${MYTMPDIR}/refmap.csv ${MYTMPDIR}/evalmap.csv

rm -rf ${MYTMPDIR}
