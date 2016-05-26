#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# create a set of test data using parameters
# based on RGxHA data, including crosslg markers
#

set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/test_scripts

#verify working directory
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata/sample_data3' ]
then
    echo wrong working directory
    exit
fi

#set parameters
MAP_SIZE=2000        #total map length
MARKER_DENSITY=2.0   #average markers per centimorgan
NUMB_LGS=28          #divided map into equally sized linkage groups
PROB_HK=0.28         #define probabilities of the three marker types (sum to 1.0)
PROB_LM=0.36

POP_SIZE=162            #how many progeny
PROB_MISSING=0.007      #per cent missing data
PROB_ERROR=0.01         #per cent genotyping errors (just a guess)

PROB_CROSSMARKER=0.0015    #create cross-linkage group markers
PROB_TYPE_ERR=0.029        #marker typing errors (ie confusing lmxll with nnxnp)

NSAMPLES=400
for i in $(seq 1 ${NSAMPLES})
do
    SUBDIR=$(printf "%03d" ${i})
    mkdir -p ${SUBDIR}
    cd ${SUBDIR}
    mkdir -p orig
    
    create_map --output-file=sample.map\
               --numb-lgs=${NUMB_LGS}\
               --map-size=${MAP_SIZE}\
               --marker-density=${MARKER_DENSITY}\
               --prob-both=${PROB_HK}\
               --prob-maternal=${PROB_LM}
               
    sample_map --input-file=sample.map\
               --output-file=tmp.loc\
               --orig-dir=orig\
               --samples=${POP_SIZE}\
               --prob-missing=${PROB_MISSING}\
               --prob-error=${PROB_ERROR}

    touch crossmarkers_list

    while [ "$(cat crossmarkers_list | wc --lines)" == "0" ]
    do
        create_type_errors.py\
            sample.map\
            tmp.loc\
            ${PROB_CROSSMARKER}\
            ${PROB_TYPE_ERR}\
            > sample.loc
    done
        
    cd ..
done
