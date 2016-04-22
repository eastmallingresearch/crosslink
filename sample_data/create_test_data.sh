#!/bin/bash

#
# create a set of test data using parameters
# based on RGxHA data, including crosslg markers
#

set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/rjv_mnt/cluster/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/sample_data

#remove everything
if [ "$(pwd)" != '/home/vicker/rjv_mnt/cluster/crosslink/ploscompbiol_data/simdata' ]
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

mkdir -p sample_data
cd sample_data

NSAMPLES=200
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

    create_type_errors.py\
        sample.map\
        tmp.loc\
        ${PROB_CROSSMARKER}\
        ${PROB_TYPE_ERR}\
        > sample.loc
        
    cd ..
done
