#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#manually convert marker types for sets of named markers

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_MAT2PAT_MARKERS=$3
CL_PAT2MAT_MARKERS=$4

#perform type switching
modify_markers.py\
    ${CL_INPUT_FILE}\
    ${CL_MAT2PAT_MARKERS}\
    ${CL_PAT2MAT_MARKERS}\
    >> ${CL_OUTPUT_FILE}
