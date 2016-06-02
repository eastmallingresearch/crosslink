#!/bin/bash

#
# convert joinmap map file into csv suitable for use with compare_maps.py
#

# usage: map2csv.sh MAPFILE PS2SNPFILE > CSVFILE

MAPFILE=$1
PS2SNPFILE=$2

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#flatten file so every line has marker,lg,pos
cat ${MAPFILE} \
    | awk -v FS=' ' -v OFS=',' '{if (/^group/) {GROUP=$2} else {print $1,GROUP,$2}}' \
    | sed 's/PHR../AX/g ; s/NMH../AX/g' \
    > ${MYTMPDIR}/probesetids.csv

#convert probesetids into SNP ids (for better intermap comparison)
probe2snp.py ${PS2SNPFILE} ${MYTMPDIR}/probesetids.csv
    
rm -rf ${MYTMPDIR}
