#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#merge two or more linkage groups
#called by cl_merge.sh

set -eu

CL_INPUT_DIR=$1
CL_LGLIST=$2
CL_OUTPUT_DIR=$3
CL_CONF_FILE=$4

source ${CL_CONF_FILE}

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

OUTNAME=${CL_OUTPUT_DIR}/${CL_LGLIST// /_}.loc  #// => replace all occurrences

#combine markers into a single file
for LGNAME in ${CL_LGLIST}
do
    INPNAME=${CL_INPUT_DIR}/${LGNAME}.loc
    cat ${INPNAME} >> ${MYTMPDIR}/tmp
    mv ${INPNAME} ${INPNAME/.loc/.old}
done

#rephase
crosslink_group\
    --inp=${MYTMPDIR}/tmp\
    --outbase=${MYTMPDIR}/\
    --min_lod=0.0

#reorder and hkimpute
crosslink_map\
    --inp=${MYTMPDIR}/000.loc --out=${OUTNAME}\
    --randomise_order=${CL_MAP_RANDOMISE} --ga_gibbs_cycles=${CL_MAP_CYCLES}\
    --ga_iters=${CL_GA_ITERS} --ga_optimise_meth=${CL_GA_OPTIMISEMETH} --ga_skip_order1=${CL_GA_SKIPORDER1}\
    --ga_use_mst=${CL_GA_USEMST} --ga_minlod=${CL_GA_MINLOD} --ga_mst_nonhk=${CL_GA_MSTNONHK}\
    --ga_prob_hop=${CL_GA_PROBHOP} --ga_max_hop=${CL_GA_MAXHOP}\
    --ga_prob_move=${CL_GA_PROBMOVE} --ga_max_mvseg=${CL_GA_MAXMOVESEG} --ga_max_mvdist=${CL_GA_MAXMOVEDIST}\
    --ga_prob_inv=${CL_GA_PROBINV} --ga_max_seg=${CL_GA_MAXSEG}\
    --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
    --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
    --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
    --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}

#clean up temp files
rm ${MYTMPDIR}/tmp  ${MYTMPDIR}/000.loc
rmdir ${MYTMPDIR}
