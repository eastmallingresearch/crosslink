#!/bin/bash

#adjust lg name and (if required) orientation

set -eu

CL_INPUT_DIR=$1
CL_VSREF_FILE=$2
CL_OUTPUT_DIR=$3
CL_OUTPUT_PREFIX=$4

mkdir -p ${CL_OUTPUT_DIR}
rm -f ${CL_OUTPUT_DIR}/*

MYTMPDIR=$(mktemp -d)

#rename and reorient (if required) all loc files
for INPNAME in ${CL_INPUT_DIR}/*.loc
do
    OLDLG=$(echo ${INPNAME} | egrep -o -e '([0-9]{3}_?)*')
    NEWLG=$(cat ${CL_VSREF_FILE} | grep -Fw ${OLDLG} | awk -v FS=',' '{print $2}')
    REVERSE=$(cat ${CL_VSREF_FILE} | grep -Fw ${OLDLG} | awk -v FS=',' '{print $3}')
    OUTNAME=${CL_OUTPUT_DIR}/${CL_OUTPUT_PREFIX}_${NEWLG}.loc
    
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
