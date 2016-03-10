#!/bin/bash

#match each linkage group to the most similar lg in a reference map

set -eu

CL_INPUT_DIR=$1
CL_REFMAP_FILE=$2
CL_PS2SNP_FILE=$3
CL_OUTPUT_BASE=$4

#extract one map position per marker, combined if available otherwise maternal or paternal
make_combined_map.py ${CL_INPUT_DIR}/*.map\
        | sed 's/PHR../AX/g ; s/NMH../AX/g'\
        > ${CL_OUTPUT_BASE}probeids.csv

#convert probesetids into SNP ids (for easier intermap comparison
probe2snp.py\
    ${CL_PS2SNP_FILE}\
    ${CL_OUTPUT_BASE}probeids.csv\
    > ${CL_OUTPUT_BASE}snpids.csv

#match lgs to reference map
match_lgs.py\
    --inp ${CL_OUTPUT_BASE}snpids.csv\
    --ref ${CL_REFMAP_FILE}\
    --out ${CL_OUTPUT_BASE}vs_ref.csv\
    --out2 ${CL_OUTPUT_BASE}mergelist\
