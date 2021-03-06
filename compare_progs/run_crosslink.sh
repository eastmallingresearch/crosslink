#$ -S /bin/bash
#$ -l h_vmem=2G
#$ -l mem_free=2G
#$ -l virtual_free=2G
#$ -l h_rt=999:00:00
###$ -l h=blacklace02.blacklace|blacklace05.blacklace|blacklace06.blacklace|blacklace03.blacklace|blacklace04.blacklace|blacklace01.blacklace
###$ -pe smp 4

#Crosslink, Copyright (C) 2016  NIAB EMR

set -eu

source ~/rjv_bashrc

export PATH=${CROSSLINK_PATH}/compare_progs:${PATH}

DIRNAME=${RANDOM}${RANDOM}
export FILEBASE=${PWD}/${SAMPLE_DIR}/sample

mkdir -p ${DIRNAME}
cd ${DIRNAME}

export TIMEFORMAT='%R %U %S'

{ time run_crosslink_inner.sh $1 2> err > out ; } 2> time

#extract one map position per marker, combined if available otherwise maternal or paternal
make_combined_map.py out000.map > final.csv

MAPSCORE=$(calc_mapping_accuracy2.sh ${FILEBASE}.map final.csv)

REALTIME=$(awk '{print $1}' time)
USERTIME=$(awk '{print $2}' time)
SYSTIME=$(awk '{print $3}' time)

echo $1 ${SAMPLE_DIR} ${REALTIME} ${USERTIME} ${SYSTIME} ${MAPSCORE} > score
