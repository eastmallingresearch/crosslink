#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00

#
# run one test to optmise crosslg marker detection parameters
#

set -eu

CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/sample_data

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${SCRIPT_DIR}

DIRNAME=${HOMEO_MINCOUNT}_${HOMEO_MINLOD}_${HOMEO_MAXLOD}_${SAMPLE_DIR}

rm -rf ${DIRNAME}
mkdir -p ${DIRNAME}
cd ${DIRNAME}

echo initial grouping...
mkdir -p groups
crosslink_group\
        --inp=../../sample_data/${SAMPLE_DIR}/sample.loc\
        --log=group.log\
        --outbase=groups/\
        --mapbase=groups/\
        --min_lod=${MINLOD}\
        --ignore_cxr=1\
        --matpat_lod=${MATPATLOD}\
        --knn=${KNN}

echo initial mapping...
mkdir -p init
for x in groups/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=init/$(basename ${x})\
        --map=init/$(basename ${x/loc/map})\
        --log=init/$(basename ${x/loc/log})\
        --ga_gibbs_cycles=${INIT_CYCLES}\
        --homeo_mincount=${HOMEO_MINCOUNT}\
        --homeo_minlod=${HOMEO_MINLOD}\
        --homeo_maxlod=${HOMEO_MAXLOD}
done

echo -n waiting for jobs to finish
while [ "$(ps | grep crosslink_map | wc --lines)" != "0" ]
do
    echo -n .
    sleep 1
done
echo ' done'

##filter out cross linkage group markers
#cat init/*.log | grep homeo | cut -d ' ' -f 2 > crossmarkers
#cat ./sample2.loc | grep -vf crossmarkers > sample3.loc

##cross lg marker detection accuracy
crosslg_score=$(calc_crosslg_accuracy.py ../../sample_data/${SAMPLE_DIR}/crossmarkers_list 'init/*.log')

echo ${HOMEO_MINCOUNT} ${HOMEO_MINLOD} ${HOMEO_MAXLOD} ${SAMPLE_DIR} ${crosslg_score} > score

rm -rf groups init group.log
