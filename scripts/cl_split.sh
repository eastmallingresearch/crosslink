#!/bin/bash

#convert loc files into joinmap format

set -u

CL_INPUT_DIR=$1
CL_OLD_DIR=$2
CL_START_LOD=$3
CL_LOD_INC=$4
CL_CONF_FILE=$5

mkdir -p ${CL_OLD_DIR}

CL_SPLIT_GLOB="${CL_INPUT_DIR}/???"
CL_SUBGROUP_MINLOD=${CL_START_LOD}

while [ true ]
do
    #check if any files match the glob
    NFILES=$(compgen -G "${CL_SPLIT_GLOB}.loc" | wc --lines)
    
    if [ "${NFILES}" == "0" ]
    then
        #no more splitting to be done
        echo done
        break
    fi

    #increment the lod
    CL_SUBGROUP_MINLOD=$(awk "BEGIN{print ${CL_SUBGROUP_MINLOD}+${CL_LOD_INC}}")

    #process each file
    for INPNAME in ${CL_SPLIT_GLOB}.loc
    do
        #show rflod plot
        echo "${INPNAME}"
        crosslink_viewer --inp=${INPNAME}
    
        #exit status depends on which key user pressed
        RET=$?
        
        if [ "${RET}" == "1" ]   ; then echo crosslink_viewer error ; break ; fi   #error
        if [ "${RET}" == "100" ] ; then echo user abort ; break ; fi               #ESCAPE: user abort
        if [ "${RET}" == "10" ]  ; then echo no splitting ; continue ; fi          #0: do not splitting
        
        #pressed '1' to apply further splitting to this LG
        if [ "${RET}" == "11" ]
        then
            CURR_LOD=${CL_SUBGROUP_MINLOD}
            OUTBASE=${CL_INPUT_DIR}/$(basename --suffix=.loc ${INPNAME})_
            
            while true
            do
                #try to subdivide
                echo splitting at LOD ${CURR_LOD}
                cl_subgroup.sh   ${INPNAME}   ${CURR_LOD}   ${OUTBASE}   ${CL_CONF_FILE}
            
                NSUBS=$(ls -1 ${OUTBASE}???.loc | wc --lines)
                
                if [ "${NSUBS}" != "1" ]
                then
                    #accept subdivision
                    echo split into ${NSUBS} at LOD ${CURR_LOD}
                    break
                fi
                
                #try again at next lod threshold
                CURR_LOD=$(awk "BEGIN{print ${CURR_LOD}+${CL_LOD_INC}}")
            done
            
            mv ${INPNAME} ${CL_OLD_DIR}
        fi
    done
    
    if [ "${RET}" == "100" ] ; then break ; fi #user abort

    #create the glob pattern for the next round of splitting
    CL_SPLIT_GLOB="${CL_SPLIT_GLOB}_???"
done
