#!/bin/bash

#
# apply redundancy filter to rgxha data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

#do not set -e otherwise crosslink_viewer cannot return which option the user selected
set -u

FNAME=RGxHA
SEED=$1

RUN_MATPAT=0
RUN_REDUN=0
RUN_KNN=0
RUN_EXTRACT=0
RUN_GROUP=0
RUN_PHASE=0
RUN_REFINE=1

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_rgxha" ]
then
    echo wrong working directory
    exit
fi

#==========matpat typing errors==============
#fix matpat typing errors
#after redundancy removal it will no longer be meaningful to count the number of original lm and np markers
#therefore fix matpat before redundancy removal
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_MATPATLOD=20.0   #lod to use for detecting mistyped markers

if [ "${RUN_MATPAT}" == "1" ]
then
    rm -f ${FNAME}_???.loc
    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_\
                    --log ${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --matpat_lod ${GRP_MATPATLOD}
                    
    cat ${FNAME}_???.loc > ${FNAME}2.loc
fi

#==========find non redundant markers==============
#generate list of non redundant markers
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_REDUNLOD=20.0    #lod to use for filtering redundant markers

if [ "${RUN_REDUN}" == "1" ]
then
    rm -f ${FNAME}2_???.loc
    crosslink_group --inp ${FNAME}2.loc\
                    --outbase ${FNAME}2_\
                    --redun ${FNAME}2.redun\
                    --log ${FNAME}2.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --redundancy_lod ${GRP_REDUNLOD}
fi

#==========knn imputation==============
#impute missing values in the markers
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_KNN=3            #how many neighbouring markers to use for imputing

if [ "${RUN_KNN}" == "1" ]
then
    crosslink_group --inp ${FNAME}2.loc\
                    --outbase ${FNAME}3_\
                    --log ${FNAME}3.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --knn ${GRP_KNN}
fi

#================extract imputed non redundant markers==============
#extract the imputed values for the nonredundant markers only
#thereby combining the output of the previous two steps

if [ "${RUN_EXTRACT}" == "1" ]
then
    #get list of just redundant marker names
    awk '{print $1}' ${FNAME}2.redun | sort -u > ${FNAME}2.redun1
    
    #retain only nonredundant markers from imputed data
    cat ${FNAME}3_???.loc | grep -vF -f ${FNAME}2.redun1 | grep -v '^;' |  cat > ${FNAME}4.tmp
    
    #create file header
    echo "; group 000 markers $(wc --lines ${FNAME}4.tmp)" > ${FNAME}4.loc
    cat ${FNAME}4.tmp >> ${FNAME}4.loc
    rm ${FNAME}4.tmp
    
fi

#==========GROUP==============
#initial grouping
GRP_MINLOD=10.0      #lod to use for initial grouping and phasing

if [ "${RUN_GROUP}" == "1" ]
then
    crosslink_group --inp ${FNAME}4.loc\
                    --outbase ${FNAME}4_\
                    --log ${FNAME}4.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}
fi

#===========phase=============
#running crosslink_group again on each lg separately to allow a lower lod to be used
#for phasing than for the initial grouping
#this feature should really be implemented directly in the program!
GRP_MINLOD=0.01      #lod to use for phasing

if [ "${RUN_PHASE}" == "1" ]
then
    for INPNAME in ${FNAME}4_???.loc
    do
        BASENAME=${INPNAME:0:${#INPNAME}-4}
        OUTNAME=$(echo ${INPNAME}|sed "s/${FNAME}4/${FNAME}5/g")
        
        crosslink_group --inp ${INPNAME}\
                        --outbase ${BASENAME}_\
                        --log ${BASENAME}.log\
                        --prng_seed ${SEED}\
                        --min_lod ${GRP_MINLOD}
                        
        mv ${BASENAME}_000.loc ${OUTNAME}
    done
fi

#===========REFINE===============
#apply further, recursive splitting to those lgs selected by the user
GRP_MINLOD=10.0
GRP_LODINC=5.0
GRP_GLOB=${FNAME}5
GRP_UNSPLIT=unsplit          #directory to move lgs which needed more splitting to

if [ "${RUN_REFINE}" == "1" ]
then
    mkdir -p ${GRP_UNSPLIT}
    #rm -f ${GRP_UNSPLIT}/${FNAME}*.loc
    
    while [ true ]
    do
        #get list of files to process this round
        GRP_GLOB="${GRP_GLOB}_???"
        NFILES=$(ls -1 ${GRP_GLOB}.loc | wc --lines)
        if [ "${NFILES}" == "0" ] ; then break ; fi #no more files to process

        #increment the lod
        PREV_LOD=${GRP_MINLOD}
        GRP_MINLOD=$(python -c "print ${GRP_MINLOD}+${GRP_LODINC}")

        #process each file
        for INPNAME in ${GRP_GLOB}.loc
        do
            #show rflod plot
            echo "${INPNAME}"
            crosslink_viewer --inp ${INPNAME} --datatype phased --minlod ${PREV_LOD}
        
            #exit status depends on which key user pressed
            RET=$?
            
            if [ "${RET}" == "1" ]   ; then echo crosslink_viewer error ; break ; fi   #error
            if [ "${RET}" == "100" ] ; then echo user abort ; break ; fi               #ESCAPE: user abort
            if [ "${RET}" == "10" ]  ; then echo no splitting ; continue ; fi          #0: do not splitting
            
            #pressed '1' to apply further splitting to this LG
            if [ "${RET}" == "11" ]
            then
                echo splitting at LOD ${GRP_MINLOD}
            
                BASENAME=$(echo ${INPNAME} | sed 's/\.loc//g')
            
                crosslink_group --inp ${INPNAME}\
                                --outbase ${BASENAME}_\
                                --log ${BASENAME}.log\
                                --prng_seed ${SEED}\
                                --min_lod ${GRP_MINLOD}
                                
                mv ${INPNAME} ${BASENAME}.log ${GRP_UNSPLIT}
            fi
        done
        
        if [ "${RET}" == "100" ] ; then break ; fi #user abort
    done
fi
