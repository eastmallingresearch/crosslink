#!/bin/bash

#
# convert Crosslink map files into a csv suitable for use with compare_maps.py
#

# usage: cl_map2csv.sh INPUTDIR OUTPUTFILE

CL_INPDIR=$1
CL_OUTFILE=$2

rm -f ${CL_OUTFILE}

#for each linkage group map file in the input directory
for INPNAME in ${CL_INPDIR}/*.map
do
    #extract LG name
    LG=$(basename ${INPNAME} .map)
    
    #extract one map position per marker, combined if available otherwise maternal or paternal
    make_combined_map.py ${INPNAME}\
            | awk -v LG="${LG}" -v FS=',' -v OFS=',' '{print $1,LG,$3}'\
            >> ${CL_OUTFILE}
done
