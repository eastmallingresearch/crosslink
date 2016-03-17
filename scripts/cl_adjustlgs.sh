#!/bin/bash

#adjust lg name and (if required) orientation

set -eu

CL_INPUT_DIR=$1
CL_VSREF_FILE=$2
CL_OUTPUT_DIR=$3

mkdir -p ${CL_OUTPUT_DIR}

MYTMPDIR=$(mktemp -d)

#rename and reorient (if required) all loc files
for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OLDLG=$(basename ${INPNAME} .loc)
    NEWLG=$(cat ${CL_VSREF_FILE} | grep "^${OLDLG}," | awk -v FS=',' '{print $2}')
    REVERSE=$(cat ${CL_VSREF_FILE} | grep "^${OLDLG}," | awk -v FS=',' '{print $3}')
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
rm ${MYTMPDIR}/tmp
rmdir ${MYTMPDIR}
