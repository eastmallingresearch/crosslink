#$ -S /bin/bash
#$ -l h_vmem=1.1G
#$ -l mem_free=1.1G
#$ -l virtual_free=1.1G
#$ -l h_rt=999:00:00
###$ -l h=blacklace02.blacklace|blacklace05.blacklace|blacklace06.blacklace|blacklace03.blacklace|blacklace04.blacklace|blacklace01.blacklace
###$ -pe smp 4

#Crosslink, Copyright (C) 2016  NIAB EMR

set -eu

source ~/rjv_bashrc

export PATH=${CROSSLINK_PATH}/compare_progs:${PATH}
export FILEBASE=${PWD}/${SAMPLE_DIR}/sample

DIRNAME=${RANDOM}${RANDOM}

mkdir -p ${DIRNAME}

cd ${DIRNAME}

export TIMEFORMAT='%R %U %S'

{ time run_onemap_inner.sh $1 2> err > out ; } 2> time

#get just the marker order
tail -n +2 sample.out | awk -v OFS=',' '{print $2,0,$3}' > final.csv

MAPSCORE=$(calc_mapping_accuracy2.sh ${FILEBASE}.map final.csv)

REALTIME=$(awk '{print $1}' time)
USERTIME=$(awk '{print $2}' time)
SYSTIME=$(awk '{print $3}' time)

echo $1 ${SAMPLE_DIR} ${REALTIME} ${USERTIME} ${SYSTIME} ${MAPSCORE} > score
