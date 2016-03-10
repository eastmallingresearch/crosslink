#!/bin/bash

#impute hks without changing marker order

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#source parameter values
source ${CL_CONF_FILE}

#make temp dir
MYTMPDIR=$(mktemp -d)

crosslink_map\
  --inp=${CL_INPUT_FILE} --out=${MYTMPDIR}/tmp.loc\
  --ga_gibbs_cycles=1 --ga_iters=0 --ga_skip_order1=1\
  --gibbs_samples=${CL_GIBBS_SAMPLES} --gibbs_burnin=${CL_GIBBS_BURNIN} --gibbs_period=${CL_GIBBS_PERIOD}\
  --gibbs_prob_sequential=${CL_GIBBS_PROBSEQUEN} --gibbs_prob_unidir=${CL_GIBBS_PROBUNIDIR}\
  --gibbs_min_prob_1=${CL_GIBBS_MINPROB1} --gibbs_min_prob_2=${CL_GIBBS_MINPROB2}\
  --gibbs_twopt_1=${CL_GIBBS_TWOPT1} --gibbs_twopt_2=${CL_GIBBS_TWOPT2}

#allow output file to overwrite input file
rm -f ${CL_OUTPUT_FILE}
mv ${MYTMPDIR}/tmp.loc ${CL_OUTPUT_FILE}

#clean up temporary dir
rmdir ${MYTMPDIR}
