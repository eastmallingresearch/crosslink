#!/bin/bash

#
# test hk imputation on simulated data
# use cxr linkage during phasing
# split hks into two arbitrary groups before imputation
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts

set -eu

FNAME=redun001
SEED=$1

RUN_REMOVE=1
RUN_CREATE=1
RUN_SAMPLE=1
RUN_GROUP=1
RUN_CALC=0

if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/test_redundancy" ]
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
MARKERS=1000
NLGS=1
CENTIMORGANS=0.1
PROB_HK=0.333
PROB_LM=0.5

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
GRP_REDUNLOD=0.0    #min lod to require before treating markers as redundant

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

