#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00

#
# run one test to optmise crosslg marker detection parameters
#

set -eu

source ~/rjv_bashrc

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
        --min_lod=10\
        --ignore_cxr=1\
        --matpat_lod=10\
        --knn=3

echo initial mapping...
mkdir -p init
for x in groups/*.loc
do
    crosslink_map\
        --seed=0\
        --inp=${x}\
        --out=init/$(basename ${x})\
        --map=init/$(basename ${x/loc/map})\
        --log=init/$(basename ${x/loc/log})\
        --randomise_order=0\
        --ga_skip_order1=1\
        --ga_gibbs_cycles=${GA_GIBBS_CYCLES}\
        --ga_iters=${GA_ITERS}\
        --ga_use_mst=${GA_USE_MST}\
        --ga_minlod=${GA_MINLOD}\
        --ga_mst_nonhk=${GA_MST_NONHK}\
        --ga_optimise_meth=${GA_OPTIMISE_METH}\
        --ga_prob_hop=${GA_PROB_HOP}\
        --ga_max_hop=${GA_MAX_HOP}\
        --ga_prob_move=${GA_PROB_MOVE}\
        --ga_max_mvseg=${GA_MAX_MVSEG}\
        --ga_max_mvdist=${GA_MAX_MVDIST}\
        --ga_prob_inv=${GA_PROB_INV}\
        --ga_max_seg=${GA_MAX_SEG}\
        --gibbs_samples=${GIBBS_SAMPLES}\
        --gibbs_burnin=${GIBBS_BURNIN}\
        --gibbs_period=${GIBBS_PERIOD}\
        --gibbs_prob_sequential=${GIBBS_PROB_SEQUENTIAL}\
        --gibbs_prob_unidir=${GIBBS_PROB_UNIDIR}\
        --gibbs_min_prob_1=${GIBBS_MIN_PROB_1}\
        --gibbs_min_prob_2=${GIBBS_MIN_PROB_2}\
        --gibbs_twopt_1=${GIBBS_TWOPT_1}\
        --gibbs_twopt_2=${GIBBS_TWOPT_2}
done

#hk imputation accuracy
hk_score=$(calc_hk_accuracy.py "../../sample_data2/${SAMPLE_DIR}/orig/*.orig" 'init/*.loc')

#hk imputation accuracy
mapping_score=$(calc_mapping_accuracy.sh ../../sample_data2/${SAMPLE_DIR}/sample.map 'init/*.map')

echo\
        ${GA_GIBBS_CYCLES}\
        ${GA_ITERS}\
        ${GA_USE_MST}\
        ${GA_MINLOD}\
        ${GA_MST_NONHK}\
        ${GA_OPTIMISE_METH}\
        ${GA_PROB_HOP}\
        ${GA_MAX_HOP}\
        ${GA_PROB_MOVE}\
        ${GA_MAX_MVSEG}\
        ${GA_MAX_MVDIST}\
        ${GA_PROB_INV}\
        ${GA_MAX_SEG}\
        ${GIBBS_SAMPLES}\
        ${GIBBS_BURNIN}\
        ${GIBBS_PERIOD}\
        ${GIBBS_PROB_SEQUENTIAL}\
        ${GIBBS_PROB_UNIDIR}\
        ${GIBBS_MIN_PROB_1}\
        ${GIBBS_MIN_PROB_2}\
        ${GIBBS_TWOPT_1}\
        ${GIBBS_TWOPT_2}\
        ${SAMPLE_DIR}\
        ${DIRNAME}\
        ${hk_score} ${mapping_score}\
        > score

rm -rf groups init group.log
