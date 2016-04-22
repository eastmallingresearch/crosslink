#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#match each linkage group to the most similar lg in a reference map

set -eu

CL_INPUT_DIR=$1
CL_REFMAP_FILE=$2
CL_PS2SNP_FILE=$3

#extract one map position per marker, combined if available otherwise maternal or paternal
make_combined_map.py ${CL_INPUT_DIR}/*.map\
        | sed 's/PHR../AX/g ; s/NMH../AX/g'\
        > probesetids.csv

#convert probesetids into SNP ids (for better intermap comparison)
probe2snp.py\
    ${CL_PS2SNP_FILE}\
    probesetids.csv\
    > snpids.csv

#match lgs to reference map
match_lgs.py\
    --inp snpids.csv\
    --ref ${CL_REFMAP_FILE}\
    --out vs_ref.csv\
    --out2 mergelist
