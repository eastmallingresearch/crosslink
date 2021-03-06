#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#try multiple reorderings of the map and keep the best one
#called by cl_refine_order

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_NUMB_TRIALS=$3

shift 3

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#initial output file is a copy of the input file
cat ${CL_INPUT_FILE} > ${MYTMPDIR}/orig
cat ${MYTMPDIR}/orig > ${CL_OUTPUT_FILE}

#get the current total map length
crosslink_pos   --inp=${MYTMPDIR}/orig   --out=${MYTMPDIR}/map
BEST_LENGTH=$(total_map_length.py ${MYTMPDIR}/map)

CL_CONF_FILE=$1
source ${CL_CONF_FILE}

#if we are going to accept the best new ordering even if worst than the previous ordering
if [ "${CL_IGNORE_PREVIOUS}" == "1" ]
then
    #set previous length the dummy bad value
    BEST_LENGTH=999999999
fi

#for each configuration file
while [ "$#" -gt "0" ]
do
    CL_CONF_FILE=$1
    shift
    source ${CL_CONF_FILE}
    
    #for each trial
    for SEED_VAL in $(seq 1 ${CL_NUMB_TRIALS})
    do
        CL_SEED=${SEED_VAL}
        if [[ -v CL_RANDOMISE_SEED ]]
        then
            if [[ "${CL_RANDOMISE_SEED}" == 1 ]]
            then
                CL_SEED=0
            fi
        fi
    
        #do the ordering
        crosslink_map\
            --inp=${MYTMPDIR}/orig --out=${MYTMPDIR}/tmp --map=${MYTMPDIR}/map --seed=${CL_SEED}\
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
    
        #get the new total map length
        NEW_LENGTH=$(total_map_length.py ${MYTMPDIR}/map)
        
        if [ "${NEW_LENGTH}" -lt "${BEST_LENGTH}" ]
        then
            echo ${CL_INPUT_FILE} ${CL_CONF_FILE} ${CL_SEED} ${BEST_LENGTH} '==>' ${NEW_LENGTH}
            BEST_LENGTH=${NEW_LENGTH}
            cat ${MYTMPDIR}/tmp > ${CL_OUTPUT_FILE}
            echo ${CL_CONF_FILE} > ${CL_OUTPUT_FILE}.conf
        fi
    done
done

rm ${MYTMPDIR}/tmp  ${MYTMPDIR}/map  ${MYTMPDIR}/orig
rmdir ${MYTMPDIR}
