#!/bin/bash

#calculate map positions without reordering markers or imputing hks

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#source parameter values
source ${CL_CONF_FILE}

crosslink_pos\
  --inp=${CL_INPUT_FILE} --map=${CL_OUTPUT_FILE}
