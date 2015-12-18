#!/bin/bash

#
# create the test maps
# called from 030_compare_progs.sh
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

TESTMAP=$1
ERATE=$2
NMARKERS=$3
REP=$4
DENSITY=$5 #markers per centimorgan

LGSIZE=$(python -c "print float(${NMARKERS})/${DENSITY}")   #correct
#LGSIZE=$(python -c "print float(${NMARKERS})*${DENSITY}")    #incorrect
POPSIZE=200

#create map with randomly placed markers
create_map --out ${TESTMAP}.map\
           --nmarkers ${NMARKERS}\
           --nlgs 1\
           --lg_size ${LGSIZE}\
           --prob_hk 0.333\
           --prob_lm 0.5\
           --hideposn 1
           
#simulate genotyping data from the markers
sample_map --inp ${TESTMAP}.map\
           --out ${TESTMAP}.loc\
           --orig ${TESTMAP}_orig.loc\
           --hide_hk_inheritance 1\
           --randomise_order 1\
           --nind ${POPSIZE}\
           --prob_missing ${ERATE}\
           --prob_error ${ERATE}\
           --map_func 1
           
#convert to tmap format
echo "data type outbred"                 >  ${TESTMAP}.loc.tmap
echo "${POPSIZE} ${NMARKERS}"            >> ${TESTMAP}.loc.tmap
tail -n +5 ${TESTMAP}.loc\
    | sed 's/ {..}//g'\
    | tr 'lmnphk' 'ababab'               >> ${TESTMAP}.loc.tmap
    
#convert to lepmap format
convert2lepmap.py ${TESTMAP}.loc\
    > ${TESTMAP}.lepmap.tmp
transpose_tsv.py ${TESTMAP}.lepmap.tmp   >  ${TESTMAP}.loc.lepmap

#convert to onemap format
convert2onemap.py ${TESTMAP}.loc         >  ${TESTMAP}.loc.onemap
           
#create file listing only marker names and cm pos in correct order 
tail -n +2 ${TESTMAP}.map\
    | awk '{print $1, $5}'               > ${TESTMAP}.map.order

