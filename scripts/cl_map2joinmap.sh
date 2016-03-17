#!/bin/bash

#convert loc files into joinmap format

set -eu

CL_INPUT_DIR=$1
CL_OUTPUT_FILE=$2

rm -f ${CL_OUTPUT_FILE}

for INPNAME in ${CL_INPUT_DIR}/*.map
do
    #extract LG name
    LG=$(basename ${INPNAME} .map)
    
    #group header
    echo "group ${LG}" >> ${CL_OUTPUT_FILE}

    #extract one map position per marker, combined if available otherwise maternal or paternal
    make_combined_map.py ${INPNAME}\
            | awk -v FS=',' -v OFS=' ' '{print $1,$3}'\
            >> ${CL_OUTPUT_FILE}
done
