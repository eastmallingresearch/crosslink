#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#fix marker typing errors

set -eu

CL_INPUT_FILE=$1
CL_OUTPUT_FILE=$2
CL_CONF_FILE=$3

source ${CL_CONF_FILE}

#make temporary directory for the output
MYTMPDIR=$(mktemp -d --tmpdir crosslink.XXXXXXXXXX)

#fix typing errors
if [[ -v CL_GROUP_LOGFILE ]]
then
    crosslink_group --inp=${CL_INPUT_FILE}\
                    --log=${CL_GROUP_LOGFILE}\
                    --outbase=${MYTMPDIR}/\
                    --min_lod=${CL_GROUP_MINLOD}\
                    --matpat_lod=${CL_GROUP_MATPATLOD}\
                    --matpat_weights=${CL_MATPAT_WEIGHTS}
else
    crosslink_group --inp=${CL_INPUT_FILE}\
                    --outbase=${MYTMPDIR}/\
                    --min_lod=${CL_GROUP_MINLOD}\
                    --matpat_lod=${CL_GROUP_MATPATLOD}\
                    --matpat_weights=${CL_MATPAT_WEIGHTS}
fi

#aggregate markers into single lg again
cat ${MYTMPDIR}/*.loc > ${CL_OUTPUT_FILE}

#clean up temporary files
rm -f ${MYTMPDIR}/*.loc
rmdir ${MYTMPDIR}
