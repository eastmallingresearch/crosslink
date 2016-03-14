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
    OLDLG=$(basename --suffix=.loc ${INPNAME})
    NEWLG=$(cat ${CL_VSREF_FILE} | grep "^${OLDLG}," | awk -v FS=',' '{print $2}')
    REVERSE=$(cat ${CL_VSREF_FILE} | grep "^${OLDLG}," | awk -v FS=',' '{print $3}')
    OUTNAME=${CL_OUTPUT_DIR}/${NEWLG}.loc
    
    #reverse order if required
    if [ "${REVERSE}" == "True" ]
    then
        tac ${INPNAME} | grep -v '^;' > ${MYTMPDIR}/tmp
    else
        cat ${INPNAME} | grep -v '^;' > ${MYTMPDIR}/tmp
    fi
    
    #create header
    echo "; group ${NEWLG} markers $(cat ${MYTMPDIR}/tmp | wc --lines)" > ${OUTNAME}
    cat ${MYTMPDIR}/tmp >> ${OUTNAME}
done

#clean up tmp
rm ${MYTMPDIR}/tmp
rmdir ${MYTMPDIR}
