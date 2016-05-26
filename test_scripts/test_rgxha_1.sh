#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# run one test to optmise crosslg marker detection for rgxha data
#

set -eu

CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${SCRIPT_DIR}

mkdir -p ${OUTDIR}
cd ${OUTDIR}

export CL_HOMEO_MINCOUNT CL_HOMEO_MINLOD CL_HOMEO_MAXLOD

cl_detect_crosslg.sh ../uniqgrps   crosslg_markers   ../conf/detectcrosslg.000

##cross lg marker detection accuracy
crosslg_score=$(calc_crosslg_accuracy2.py ../conf/badmarkers crosslg_markers)

echo ${CL_HOMEO_MINCOUNT} ${CL_HOMEO_MINLOD} ${CL_HOMEO_MAXLOD} ${CL_HOMEO_MINCOUNT}_${CL_HOMEO_MINLOD}_${CL_HOMEO_MAXLOD} ${OUTDIR} ${crosslg_score} > score

rm -rf groups init group.log phased
