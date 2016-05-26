#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# run one test to optmise crosslg marker detection parameters
#

set -eu

source ~/rjv_bashrc

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

DIRNAME=${RANDOM}${RANDOM}

mkdir -p ${DIRNAME}
cd ${DIRNAME}

echo initial grouping...
mkdir -p groups
crosslink_group\
        --seed=0\
        --inp=../../sample_data2/${SAMPLE_DIR}/sample.loc\
        --log=group.log\
        --outbase=groups/\
        --mapbase=groups/\
        --min_lod=${MINLOD}\
        --ignore_cxr=1\
        --mst_nonhk=${NONHK}\
        --matpat_lod=10\
        --knn=3

#count uncorrected typing errors and number of false corrections
typeerr_score=$(calc_typeerr_accuracy.py ../../sample_data2/${SAMPLE_DIR}/typeerrmarkers_list group.log)

#grouping accuracy
group_score=$(calc_grouping_accuracy.py "../../sample_data2/${SAMPLE_DIR}/orig/*.orig" 'groups/*.loc')

#phasing accuracy
phase_score=$(calc_phasing_accuracy.py "../../sample_data2/${SAMPLE_DIR}/orig/*.orig" 'groups/*.loc')

#knn imputation accuracy
knn_score=$(calc_imputation_accuracy.py "../../sample_data2/${SAMPLE_DIR}/orig/*.orig" ../../sample_data2/${SAMPLE_DIR}/tmp.loc 'groups/*.loc')

#hk imputation accuracy
map_score=$(calc_mapping_accuracy.sh ../../sample_data2/${SAMPLE_DIR}/sample.map 'groups/*.map')

echo ${MINLOD} ${NONHK} ${SAMPLE_DIR} ${typeerr_score} ${group_score} ${phase_score} ${knn_score} ${map_score} > score

rm -rf groups init group.log
