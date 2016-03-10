#!/bin/bash

#get a list of redundant markers

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

#example parameters
#CL_GROUP_MINLOD=5.0
#CL_GROUP_REDUNLOD=20.0
source ${CL_CONF_FILE}

crosslink_group --inp=${CL_INPUT_FILE}\
                --redun=${CL_OUTPUT_FILE}\
                --min_lod=${CL_GROUP_MINLOD}\
                --redundancy_lod=${CL_GROUP_REDUNLOD}

