#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# apply process rgxha data
# now with redundancy removal
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

#do not set -e otherwise crosslink_viewer cannot return which option the user selected
set -u

FNAME=RGxHA
SEED=1

RUN_REMOVEALL=0
RUN_PREFILTER=0
RUN_GROUP1=0
RUN_MATPAT=0
RUN_REDUN=0
RUN_KNN=0
RUN_EXTRACT=0
RUN_GROUP2=0
RUN_PHASE=0
RUN_MAP1=0
RUN_VIEW=0
RUN_REFINE=0
RUN_MAP2=1

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_rgxha" ]
then
    echo wrong working directory
    exit
fi

#==========start again===========
if [ "${RUN_REMOVEALL}" == "1" ]
then
    rm -f ${FNAME}* unsplit/${FNAME}*
    cp orig/RGxHA.loc .
fi

#==========prefilter===========
#remove bad markers, type switch some markers
if [ "${RUN_PREFILTER}" == "1" ]
then
    #remove "bad" markers and file header
    cat ${FNAME}.loc\
        | grep -vF -f orig/bad_markers\
        | grep -v '^;'\
        | cat\
        > ${FNAME}.tmp
    
    #create new file header
    echo "; group 000 markers $(wc --lines ${FNAME}.tmp)" > ${FNAME}0.loc

    #perform type switching
    modify_markers.py ${FNAME}.tmp orig/mat2pat orig/pat2mat >> ${FNAME}0.loc
    rm ${FNAME}.tmp
fi

#==========GROUP==============
#initial grouping
GRP_MINLOD=6.0      #lod to use for initial grouping and phasing

if [ "${RUN_GROUP1}" == "1" ]
then
    rm -f ${FNAME}1_???.loc
    crosslink_group --inp ${FNAME}0.loc\
                    --outbase ${FNAME}1_\
                    --log ${FNAME}1.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}
fi

#==========matpat typing errors==============
#fix matpat typing errors
#after redundancy removal it will no longer be meaningful to count the number of original lm and np markers
#therefore fix matpat before redundancy removal
GRP_MINLOD=6.0      #lod to use for grouping and phasing
GRP_MATPATLOD=20.0   #lod to use for detecting mistyped markers

if [ "${RUN_MATPAT}" == "1" ]
then
    rm -f ${FNAME}_???.loc
    crosslink_group --inp ${FNAME}0.loc\
                    --outbase ${FNAME}_\
                    --log ${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --matpat_lod ${GRP_MATPATLOD}
    cat ${FNAME}_???.loc > ${FNAME}2.loc
    
    echo checking if any PHR markers were type switched
    cat ./RGxHA.log | grep PHR
    echo done
fi

#==========find non redundant markers==============
#generate list of non redundant markers
GRP_MINLOD=6.0      #lod to use for grouping and phasing
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
GRP_MINLOD=6.0      #lod to use for grouping and phasing
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
#also remove "bad" markers
if [ "${RUN_EXTRACT}" == "1" ]
then
    #get list of just redundant marker names
    awk '{print $1}' ${FNAME}2.redun | sort -u > ${FNAME}2.redun1
    
    #retain only nonredundant markers from imputed data
    cat ${FNAME}3_???.loc\
        | grep -vF -f ${FNAME}2.redun1\
        | grep -v '^;'\
        | cat > ${FNAME}4.tmp
    
    #create file header
    echo "; group 000 markers $(wc --lines ${FNAME}4.tmp)" > ${FNAME}4.loc
    cat ${FNAME}4.tmp >> ${FNAME}4.loc
    rm ${FNAME}4.tmp
fi

#==========GROUP==============
#initial grouping
GRP_MINLOD=6.0      #lod to use for initial grouping and phasing

if [ "${RUN_GROUP2}" == "1" ]
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

if [ "${RUN_PHASE}" == "1" ]
then
    for INPNAME in ${FNAME}4_???.loc
    do
        BASENAME=${INPNAME:0:${#INPNAME}-4}
        OUTNAME=${INPNAME}2
        
        crosslink_group --inp ${INPNAME}\
                        --outbase ${BASENAME}_\
                        --log ${BASENAME}.log\
                        --prng_seed ${SEED}\
                        --min_lod 0.0
                        
        mv ${BASENAME}_000.loc ${OUTNAME}
    done
fi

#================map=================
MAP_CYCLES=5
MAP_RANDOMISE=0
MAP_SKIP_ORDER1=1

#ga options
GA_ITERS=300000
GA_OPTIMISE_DIST=0

#single marker hop mutation
GA_PROB_HOP=0.333
GA_MAX_HOP=1.0
#segment move parameters
GA_PROB_MOVE=0.5
GA_MAX_MOVESEG=1.0
GA_MAX_MOVEDIST=1.0
GA_PROB_INV=0.5
#segment inversion parameters
GA_MAX_SEG=1.0

#gibbs options
GIBBS_SAMPLES=200
GIBBS_BURNIN=10
GIBBS_PERIOD=1
GIBBS_PROB_SEQUENTIAL=1.0
GIBBS_PROB_UNIDIR=1.0
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

if [ "${RUN_MAP1}" == "1" ]
then
    INP_GLOB="${FNAME}4_???.loc2"
    #INP_GLOB=RGxHA4_002_000.loc2

    for INPNAME in ${INP_GLOB}
    do
        BASENAME=${INPNAME:0:${#INPNAME}-5}
        
        echo ${INPNAME}
        
        crosslink_map\
              --inp             ${INPNAME}\
              --out             ${BASENAME}.loc3\
              --log             ${BASENAME}.log3\
              --prng_seed       ${SEED}\
              --ga_gibbs_cycles ${MAP_CYCLES} --randomise_order ${MAP_RANDOMISE} --ga_iters         ${GA_ITERS} --ga_optimise_dist ${GA_OPTIMISE_DIST} --ga_skip_order1   ${MAP_SKIP_ORDER1} --ga_prob_hop      ${GA_PROB_HOP} --ga_max_hop       ${GA_MAX_HOP} --ga_prob_move     ${GA_PROB_MOVE} --ga_max_mvseg     ${GA_MAX_MOVESEG} --ga_max_mvdist    ${GA_MAX_MOVEDIST} --ga_prob_inv      ${GA_PROB_INV} --ga_max_seg       ${GA_MAX_SEG}\
              --gibbs_samples         ${GIBBS_SAMPLES} --gibbs_burnin          ${GIBBS_BURNIN} --gibbs_period          ${GIBBS_PERIOD} --gibbs_prob_sequential ${GIBBS_PROB_SEQUENTIAL} --gibbs_prob_unidir     ${GIBBS_PROB_UNIDIR} --gibbs_min_prob_1      ${GIBBS_MIN_PROB_1} --gibbs_min_prob_2      ${GIBBS_MIN_PROB_2} --gibbs_twopt_1         ${GIBBS_TWOPT_1} --gibbs_twopt_2         ${GIBBS_TWOPT_2} &
    done
fi

#===========VIEW===============
#view all lgs before starting the refinement process

if [ "${RUN_VIEW}" == "1" ]
then
    #process each file
    for INPNAME in ${FNAME}4_*.loc3
    do
        #show rflod plot
        echo "${INPNAME}"
        crosslink_viewer --inp ${INPNAME} --datatype imputed --minlod ${GRP_MINLOD}
        RET=$?
        if [ "${RET}" == "100" ] ; then echo user abort ; break ; fi               #ESCAPE: user abort
    done
fi

#===========REFINE===============
#apply further, recursive splitting to those lgs selected by the user
GRP_MINLOD=6.0
GRP_LODINC=2.0
GRP_GLOB=${FNAME}4
GRP_UNSPLIT=unsplit          #directory to move lgs which needed more splitting to

if [ "${RUN_REFINE}" == "1" ]
then
    mkdir -p ${GRP_UNSPLIT}
    #rm -f ${GRP_UNSPLIT}/${FNAME}*.loc
    
    while [ true ]
    do
        #get list of files to process this round
        GRP_GLOB="${GRP_GLOB}_???"
        NFILES=$(compgen -G "${GRP_GLOB}.loc3" | wc --lines)
        
        if [ "${NFILES}" == "0" ]
        then
            #no more splitting to be done
            echo done
            break
        fi

        #increment the lod
        PREV_LOD=${GRP_MINLOD}
        GRP_MINLOD=$(python -c "print ${GRP_MINLOD}+${GRP_LODINC}")

        #process each file
        for INPNAME in ${GRP_GLOB}.loc3
        do
            #show rflod plot
            echo "${INPNAME}"
            crosslink_viewer --inp ${INPNAME} --datatype imputed --minlod ${PREV_LOD}
        
            #exit status depends on which key user pressed
            RET=$?
            
            if [ "${RET}" == "1" ]   ; then echo crosslink_viewer error ; break ; fi   #error
            if [ "${RET}" == "100" ] ; then echo user abort ; break ; fi               #ESCAPE: user abort
            if [ "${RET}" == "10" ]  ; then echo no splitting ; continue ; fi          #0: do not splitting
            
            #pressed '1' to apply further splitting to this LG
            if [ "${RET}" == "11" ]
            then
                echo splitting at LOD ${GRP_MINLOD}
            
                BASENAME=${INPNAME:0:${#INPNAME}-5}
            
                #group
                crosslink_group --inp ${INPNAME}\
                                --outbase ${BASENAME}_\
                                --log ${BASENAME}.log\
                                --prng_seed ${SEED}\
                                --min_lod ${GRP_MINLOD}
                                
                #phase and map
                for INP2 in ${BASENAME}_???.loc
                do
                    BASE2=${INP2:0:${#INP2}-4}
                    
                    crosslink_group --inp ${INP2}\
                                    --outbase ${BASE2}_\
                                    --log ${BASE2}.log\
                                    --prng_seed ${SEED}\
                                    --min_lod 0.0
                                    
                    mv ${BASE2}_000.loc ${INP2}2
                    
                    nice crosslink_map\
                          --inp             ${INP2}2\
                          --out             ${BASE2}.loc3\
                          --map             ${BASE2}.map3\
                          --log             ${BASE2}.log3\
                          --prng_seed       ${SEED}\
                          --ga_gibbs_cycles ${MAP_CYCLES} --randomise_order ${MAP_RANDOMISE} --ga_iters         ${GA_ITERS} --ga_optimise_dist ${GA_OPTIMISE_DIST} --ga_skip_order1   ${MAP_SKIP_ORDER1} --ga_prob_hop      ${GA_PROB_HOP} --ga_max_hop       ${GA_MAX_HOP} --ga_prob_move     ${GA_PROB_MOVE} --ga_max_mvseg     ${GA_MAX_MOVESEG} --ga_max_mvdist    ${GA_MAX_MOVEDIST} --ga_prob_inv      ${GA_PROB_INV} --ga_max_seg       ${GA_MAX_SEG}\
                          --gibbs_samples         ${GIBBS_SAMPLES} --gibbs_burnin          ${GIBBS_BURNIN} --gibbs_period          ${GIBBS_PERIOD} --gibbs_prob_sequential ${GIBBS_PROB_SEQUENTIAL} --gibbs_prob_unidir     ${GIBBS_PROB_UNIDIR} --gibbs_min_prob_1      ${GIBBS_MIN_PROB_1} --gibbs_min_prob_2      ${GIBBS_MIN_PROB_2} --gibbs_twopt_1         ${GIBBS_TWOPT_1} --gibbs_twopt_2         ${GIBBS_TWOPT_2} 
                done
                
                mv ${INPNAME} ${GRP_UNSPLIT}
            fi
        done
        
        if [ "${RET}" == "100" ] ; then break ; fi #user abort
    done
fi

#================map=================
#attempt final map ordering and imputation
MAP_CYCLES=5
MAP_RANDOMISE=0
MAP_SKIP_ORDER1=1

#ga options
GA_ITERS=1000000
GA_OPTIMISE_DIST=0

#single marker hop mutation
GA_PROB_HOP=0.333
GA_MAX_HOP=1.0
#segment move parameters
GA_PROB_MOVE=0.5
GA_MAX_MOVESEG=1.0
GA_MAX_MOVEDIST=1.0
GA_PROB_INV=0.5
#segment inversion parameters
GA_MAX_SEG=1.0

#gibbs options
GIBBS_SAMPLES=400
GIBBS_BURNIN=20
GIBBS_PERIOD=1
GIBBS_PROB_SEQUENTIAL=1.0
GIBBS_PROB_UNIDIR=0.9
GIBBS_MIN_PROB_1=0.1
GIBBS_MIN_PROB_2=0.0
GIBBS_TWOPT_1=0.1
GIBBS_TWOPT_2=0.0

if [ "${RUN_MAP2}" == "1" ]
then
    INP_GLOB="${FNAME}4_*.loc3"
    #INP_GLOB=RGxHA4_002_000.loc2

    for INPNAME in ${INP_GLOB}
    do
        BASENAME=${INPNAME:0:${#INPNAME}-5}
        
        echo ${INPNAME}
        
        nice crosslink_map\
              --inp             ${INPNAME}\
              --out             ${BASENAME}.loc4\
              --map             ${BASENAME}.map4\
              --log             ${BASENAME}.log4\
              --prng_seed       ${SEED}\
              --ga_gibbs_cycles ${MAP_CYCLES} --randomise_order ${MAP_RANDOMISE} --ga_iters         ${GA_ITERS} --ga_optimise_dist ${GA_OPTIMISE_DIST} --ga_skip_order1   ${MAP_SKIP_ORDER1} --ga_prob_hop      ${GA_PROB_HOP} --ga_max_hop       ${GA_MAX_HOP} --ga_prob_move     ${GA_PROB_MOVE} --ga_max_mvseg     ${GA_MAX_MOVESEG} --ga_max_mvdist    ${GA_MAX_MOVEDIST} --ga_prob_inv      ${GA_PROB_INV} --ga_max_seg       ${GA_MAX_SEG}\
              --gibbs_samples         ${GIBBS_SAMPLES} --gibbs_burnin          ${GIBBS_BURNIN} --gibbs_period          ${GIBBS_PERIOD} --gibbs_prob_sequential ${GIBBS_PROB_SEQUENTIAL} --gibbs_prob_unidir     ${GIBBS_PROB_UNIDIR} --gibbs_min_prob_1      ${GIBBS_MIN_PROB_1} --gibbs_min_prob_2      ${GIBBS_MIN_PROB_2} --gibbs_twopt_1         ${GIBBS_TWOPT_1} --gibbs_twopt_2         ${GIBBS_TWOPT_2} &
    done
fi

