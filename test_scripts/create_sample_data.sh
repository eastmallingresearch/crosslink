#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# create a sample data set
#

set -eu

#change this to point towards the crosslink directory containing create_map and sample_map
CROSSLINK_PATH=~/git_repos/crosslink/scripts

export PATH=${CROSSLINK_PATH}:${PATH}

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

