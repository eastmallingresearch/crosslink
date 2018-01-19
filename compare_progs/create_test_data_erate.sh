#!/bin/bash

#Crosslink
#Copyright (C) 2017  NIAB EMR
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along
#with this program; if not, write to the Free Software Foundation, Inc.,
#51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#contact:
#robert.vickerstaff@emr.ac.uk
#Robert Vickerstaff
#NIAB EMR
#New Road
#East Malling
#WEST MALLING
#ME19 6BJ
#United Kingdom


#
# create test data varying the error/missing data rate
# convert each dataset into the formats required by lepmap2, onemap and tmap
# no polyploid related errors
# only one linkage group
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/bin
export PATH=${PATH}:/home/vicker/git_repos/crosslink/compare_progs

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/erate_simdata/sample_data

mkdir -p ${OUTDIR}
cd ${OUTDIR}

NSAMPLES=8

#set parameters
MAP_SIZE=100            #total map length
MARKER_DENSITY=1.5      #average markers per centimorgan
NUMB_LGS=1              #divided map into equally sized linkage groups
PROB_HK=0.28            #define probabilities of the three marker types (sum to 1.0)
PROB_LM=0.36

POP_SIZE=200            #how many progeny
#PROB_MISSING=0.007     #per cent missing data
#PROB_ERROR=0.005       #per cent genotyping errors (just a guess)

PROB_CROSSMARKER=0.0    #create cross-linkage group markers
PROB_TYPE_ERR=0.0       #marker typing errors (ie confusing lmxll with nnxnp)

for i in $(seq 1 ${NSAMPLES})
do
    for PROB_ERROR in 0.001 0.005 0.01 0.03 0.06
    do
        PROB_MISSING=${PROB_ERROR}
        SUBDIR=${PROB_ERROR}_${RANDOM}${RANDOM}
        mkdir -p ${SUBDIR}
        cd ${SUBDIR}
        mkdir -p orig

        create_map\
            --random-seed=0\
            --output-file=sample.map\
            --numb-lgs=${NUMB_LGS}\
            --map-size=${MAP_SIZE}\
            --marker-density=${MARKER_DENSITY}\
            --prob-both=${PROB_HK}\
            --prob-maternal=${PROB_LM}

        sample_map\
            --random-seed=0\
            --input-file=sample.map\
            --output-file=sample.loc\
            --orig-dir=orig\
            --samples=${POP_SIZE}\
            --prob-missing=${PROB_MISSING}\
            --prob-error=${PROB_ERROR}

        NMARKERS=$(cat sample.loc | wc --lines)

        #convert to lepmap2 format
        convert2lepmap.py sample.loc ${NMARKERS} ${POP_SIZE} > lepmap.tmp
        transpose_tsv.py lepmap.tmp > sample.lepmap
        rm lepmap.tmp

        #convert to tmap format
        echo "data type outbred"       >  sample.tmap
        echo "${POP_SIZE} ${NMARKERS}" >> sample.tmap
        cat sample.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> sample.tmap

        #convert to onemap format
        convert2onemap.py sample.loc ${NMARKERS} ${POP_SIZE} > sample.onemap

        cd ..
    done
done
