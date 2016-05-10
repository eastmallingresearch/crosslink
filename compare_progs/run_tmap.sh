#$ -S /bin/bash
#$ -l h_vmem=1.1G
#$ -l mem_free=1.1G
#$ -l virtual_free=1.1G
#$ -l h_rt=999:00:00
###$ -l h=blacklace02.blacklace|blacklace05.blacklace|blacklace06.blacklace|blacklace03.blacklace|blacklace04.blacklace|blacklace01.blacklace
###$ -pe smp 4

set -eu

source ~/rjv_bashrc

export PATH=${CROSSLINK_PATH}/compare_progs:${PATH}

DIRNAME=${RANDOM}${RANDOM}

mkdir -p ${DIRNAME}
cd ${DIRNAME}

export FILEBASE=/home/vicker/crosslink/ploscompbiol_data/compare_simdata/sample_data/${SAMPLE_DIR}/sample

export TIMEFORMAT='%R %U %S'

{ time run_tmap_inner.sh 2> err > out ; } 2> time

#get just the marker order
tail -n +2 sample.out | awk -v OFS=',' '{print $1,0,$2}' > final.csv

MAPSCORE=$(calc_mapping_accuracy2.sh ${FILEBASE}.map final.csv)

REALTIME=$(awk '{print $1}' time)
USERTIME=$(awk '{print $2}' time)
SYSTIME=$(awk '{print $3}' time)

echo tmap ${SAMPLE_DIR} ${REALTIME} ${USERTIME} ${SYSTIME} ${MAPSCORE} > score
