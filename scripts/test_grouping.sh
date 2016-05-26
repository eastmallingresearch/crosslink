#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# test hk imputation on simulated data
# use cxr linkage during phasing
# split hks into two arbitrary groups before imputation
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -eu

FNAME=grouping001
SEED=$1

RUN_REMOVE=1
RUN_CREATE=1
RUN_SAMPLE=1
RUN_GROUP=1
RUN_CALC=0

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_hk_imputation" ]
then
    echo unexpected working directory, aborting
    exit
fi

#===========remove previous results
if [ "${RUN_REMOVE}" == "1" ]
then
    rm -f ${FNAME}*
fi

#=========create map=========
MARKERS=12000
NLGS=28
CENTIMORGANS=70.0
PROB_HK=0.16
PROB_LM=0.53

if [ "${RUN_CREATE}" == "1" ]
then
    create_map\
        --out ${FNAME}.map\
        --nlgs ${NLGS}\
        --nmarkers ${MARKERS}\
        --prng_seed ${SEED}\
        --lg_size ${CENTIMORGANS}\
        --prob_hk ${PROB_HK}\
        --prob_lm ${PROB_LM}
fi

#==============sample map ===================
POPSIZE=200
MISSING=0
ERROR=0
TYPEERR=0

if [ "${RUN_SAMPLE}" == "1" ]
then
    sample_map\
        --inp ${FNAME}.map\
        --out ${FNAME}.loc\
        --orig ${FNAME}.origloc\
        --nind ${POPSIZE}\
        --prng_seed ${SEED}\
        --prob_missing ${MISSING}\
        --prob_error ${ERROR}\
        --prob_type_error ${TYPEERR}
fi

#============GROUP==============
#group options
GRP_MINLOD=10.0      #lod to use for grouping and phasing
GRP_IGNORECXR=0      #whether to ignore cxr and rxc linkage which only provides partial phasing information
GRP_REDUNLOD=10.0    #min lod to require before treating markers as redundant

if [ "${RUN_GROUP}" == "1" ]
then
    #gdb --args
    crosslink_group --inp ${FNAME}.loc\
                    --outbase ${FNAME}_\
                    --redun ${FNAME}.redun\
                    --log ${FNAME}.log\
                    --prng_seed ${SEED}\
                    --min_lod ${GRP_MINLOD}\
                    --ignore_cxr ${GRP_IGNORECXR}\
                    --redundancy_lod ${GRP_REDUNLOD}
fi

#=============calc===============
#calc grouping accuracy
if [ "${RUN_CALC}" == "1" ]
then
    calc_grouping_accuracy.py ${FNAME}.origloc ${FNAME}_???.loc

fi
