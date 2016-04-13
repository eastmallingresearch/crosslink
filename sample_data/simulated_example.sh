#!/bin/bash

#
# create a sample data set
#

set -eu

#change this to point towards the crosslink directory containing create_map, sample_map etc
CROSSLINK_PATH=/home/vicker/rjv_mnt/cluster/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/sample_data

#create a map
MAP_SIZE=500         #500cM total map length
MARKER_DENSITY=1.0   #average of 1 marker per centimorgan
NUMB_LGS=10          #divided map into 10 equally sized linkage groups
PROB_HK=0.333        #equal probabilities of the three marker types
PROB_LM=0.333

create_map --output-file=sample.map\
           --numb-lgs=${NUMB_LGS}\
           --map-size=${MAP_SIZE}\
           --marker-density=${MARKER_DENSITY}\
           --prob-both=${PROB_HK}\
           --prob-maternal=${PROB_LM}
           
#sample data from it
POP_SIZE=200            #simulate genotypes from 200 progeny
PROB_MISSING=0.01       #1% missing data
PROB_ERROR=0.01         #1% genotyping errors
PROB_TYPE_ERR=0.05      #5% marker typing errors (ie confusing lmxll with nnxnp)

sample_map --input-file=sample.map\
           --output-file=sample.loc\
           --orig-file=sample_orig.loc\
           --samples=${POP_SIZE}\
           --prob-missing=${PROB_MISSING}\
           --prob-error=${PROB_ERROR}\
           --prob-type-err=${PROB_TYPE_ERR}

#group
MINLOD=5.0       #form linkage groups using this linkage LOD threshold
IGNORECXR=1      #ignore cxr and rxc coupling between hkxhk markers during linkage group formation
MATPATLOD=10.0   #correct marker typing errors using this LOD threshold
KNN=3            #imputing missing values to the most common of the three nearest markers

mkdir -p groups
crosslink_group\
        --inp=sample.loc\
        --log=group.log\
        --outbase=groups/\
        --mapbase=maps/\
        --min_lod=${MINLOD}\
        --ignore_cxr=${IGNORECXR}\
        --matpat_lod=${MATPATLOD}\
        --knn=${KNN}

#make final map
mkdir -p final
for x in groups/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=final/$(basename ${x})\
        --map=final/$(basename ${x/loc/map}) &
done

