#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#adjust lg name and (if required) orientation to match a reference map

set -eu

CL_INPUT_DIR=$1
CL_REFMAP_FILE=$2
CL_OUTPUT_DIR=$3

mkdir -p ${CL_OUTPUT_DIR}

MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#extract one map position per marker, combined if available otherwise maternal or paternal
make_combined_map.py ${CL_INPUT_DIR}/*.map > ${MYTMPDIR}/snpids.csv
        
#match lgs to reference map
match_lgs.py\
    --inp ${MYTMPDIR}/snpids.csv\
    --ref ${CL_REFMAP_FILE}\
    --out ${MYTMPDIR}/vs_ref.csv\
    --out2 ${MYTMPDIR}/mergelist

#rename and reorient (if required) all loc files
for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OLDLG=$(basename ${INPNAME} .loc)
    NEWLG=$(cat ${MYTMPDIR}/vs_ref.csv | grep "^${OLDLG}," | awk -v FS=',' '{print $2}')
    REVERSE=$(cat ${MYTMPDIR}/vs_ref.csv | grep "^${OLDLG}," | awk -v FS=',' '{print $3}')
    OUTNAME=${CL_OUTPUT_DIR}/${NEWLG}.loc
    
    #reverse order if required
    if [ "${REVERSE}" == "True" ]
    then
        tac ${INPNAME} > ${MYTMPDIR}/tmp
    else
        cat ${INPNAME} > ${MYTMPDIR}/tmp
    fi
    
    cat ${MYTMPDIR}/tmp > ${OUTNAME}
done

#clean up tmp
rm ${MYTMPDIR}/snpids.csv
rm ${MYTMPDIR}/vs_ref.csv
rm ${MYTMPDIR}/mergelist
rm ${MYTMPDIR}/tmp
rmdir ${MYTMPDIR}
