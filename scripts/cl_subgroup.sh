#!/bin/bash

#attempt to subdivide an existing lg using a new LOD

set -eu

CL_INPUT_FILE=$1
CL_SUBGROUP_MINLOD=$2
CL_OUTPUT_DIR=$3
CL_CONF_FILE=$4

source ${CL_CONF_FILE}

MYTMPDIR=$(mktemp -d)

#initial grouping
crosslink_group\
        --inp=${CL_INPUT_FILE}\
        --outbase=${MYTMPDIR}/\
        --min_lod=${CL_SUBGROUP_MINLOD}

#count number of subgroups
NFILES=$(compgen -G "${MYTMPDIR}/*.loc" | wc --lines)

if [ "${NFILES}" == "1" ]
then
    echo no subgroups formed at LOD ${CL_SUBGROUP_MINLOD}
    rm ${MYTMPDIR}/*.loc
    rmdir ${MYTMPDIR}
    exit
fi

echo ${NFILES} subgroups formed at LOD ${CL_SUBGROUP_MINLOD}

#phase and map each new subgroup
for INPNAME in ${MYTMPDIR}/*.loc
do
    #phase
    crosslink_group --inp=${INPNAME}\
                    --outbase=${INPNAME}\
                    --min_lod=0.0
                    
    #order and hkimpute
    crosslink_map\
        --inp=${INPNAME}000.loc --out=${INPNAME}\
        --randomise_order=${CL_MAP_RANDOMISE} --ga_gibbs_cycles=${CL_MAP_CYCLES}\
        --ga_iters=${CL_GA_ITERS} --ga_optimise_dist=${CL_GA_OPTIMISEDIST} --ga_skip_order1=${CL_GA_SKIPORDER1}\
        --ga_optimise_global=${CL_GA_OPTIMISEGLOBAL}\
        --ga_use_mst=${CL_GA_USEMST} --ga_mst_minlod=${CL_GA_MSTMINLOD} --ga_mst_nonhk=${CL_GA_MSTNONHK}\
        --ga_prob_hop=${CL_GA_PROBHOP} --ga_max_hop=${CL_GA_MAXHOP}\
        --ga_prob_move=${CL_GA_PROBMOVE} --ga_max_mvseg=${CL_GA_MAXMOVESEG} --ga_max_mvdist=${CL_GA_MAXMOVEDIST}\
        --ga_prob_inv=${CL_GA_PROBINV} --ga_max_seg=${CL_GA_MAXSEG}\
        --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
        --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
        --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
        --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}
        
    #move to final position
    LGNUMB=$(basename ${INPNAME} .loc)
    BASENAME=$(basename ${CL_INPUT_FILE} .loc)
    
    cat ${INPNAME} > ${CL_OUTPUT_DIR}/${BASENAME}.${LGNUMB}.loc
done

#mark original lg file as old
mv ${CL_INPUT_FILE} ${CL_INPUT_FILE/.loc/.old}

#clean up temp files
rm ${MYTMPDIR}/*.loc
rmdir ${MYTMPDIR}
