#!/bin/bash
#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00

#
# run one test to optmise crosslg marker detection parameters
#

set -eu

CROSSLINK_PATH=/home/vicker/rjv_mnt/cluster/git_repos/crosslink

export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/bin

mkdir -p groups
crosslink_group\
        --inp=001/sample.loc\
        --log=group.log\
        --outbase=groups/\
        --min_lod=10\
        --ignore_cxr=1\
        --matpat_lod=10\
        --knn=1

mkdir -p phased
for x in groups/*.loc
do
    outbase=$(basename ${x} ".loc" )
    crosslink_group\
            --inp=${x}\
            --outbase=phased/${outbase}_\
            --min_lod=0
done  

mkdir -p init
for x in phased/*.loc
do
    outbase=$(basename ${x} "_000.loc" )
    crosslink_map\
        --inp=${x}\
        --out=init/${outbase}.loc\
        --map=init/${outbase}.map\
        --log=init/${outbase}.log\
        --randomise_order=0\
        --ga_skip_order1=1\
        --ga_gibbs_cycles=5\
        --ga_iters=150000\
        --ga_use_mst=99\
        --ga_minlod=3\
        --ga_mst_nonhk=0\
        --ga_optimise_meth=0\
        --ga_prob_hop=0.333\
        --ga_max_hop=0.5\
        --ga_prob_move=0.333\
        --ga_max_mvseg=0.5\
        --ga_max_mvdist=0.5\
        --ga_prob_inv=0.5\
        --ga_max_seg=0.5\
        --gibbs_samples=200\
        --gibbs_burnin=5\
        --gibbs_period=1\
        --gibbs_prob_sequential=0.0\
        --gibbs_prob_unidir=0.75\
        --gibbs_min_prob_1=0.1\
        --gibbs_min_prob_2=0.0\
        --gibbs_twopt_1=1.0\
        --gibbs_twopt_2=0.5\
        --homeo_mincount=7\
        --homeo_minlod=0.5\
        --homeo_maxlod=30
done


##cross lg marker detection accuracy
crosslg_score=$(calc_crosslg_accuracy.py 001/crossmarkers_list 'init/*.log')

echo ${HOMEO_MINCOUNT} ${HOMEO_MINLOD} ${HOMEO_MAXLOD} ${SAMPLE_DIR} ${crosslg_score} > score

#rm -rf groups init group.log
