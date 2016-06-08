#!/bin/bash

#
# convert probesetid marker names into canonical Affymetrix snp ids
# to allow cross map synteny comparisons
# P2SFILE is IStraw90.r1.ps2snp_map.ps available from:
# http://media.affymetrix.com/analysis/downloads/lf/genotyping/IStraw90/
# (accessed 2016-06-06)
#

# usage: probe2snp.sh INPFILE P2SFILE OUTFILE

INPFILE=$1
P2SFILE=$2
OUTFILE=$3

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#convert EMR marker names into canonical Affymetrix probesetid names
cat ${INPFILE} \
    | sed 's/PHR../AX/g ; s/NMH../AX/g' \
    > ${MYTMPDIR}/probesetids.csv

#convert canonical probesetids into canonical SNP ids
probe2snp.py ${P2SFILE} ${MYTMPDIR}/probesetids.csv > ${OUTFILE}
    
rm -rf ${MYTMPDIR}
