#!/bin/bash

#
# test crosslink_group on simulated data
# test phasing
# plot using boxplot_phasing.R

#cluster
export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/simdata
export PATH=${PATH}:/home/vicker/git_repos/rjvbio/utils

#laptop
#export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts
#export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/simdata

#dockerhost
export PATH=${PATH}:/home/vicker/nfs_mount/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/nfs_mount/git_repos/crosslink/simdata
export PATH=${PATH}:/home/vicker/nfs_mount/git_repos/rjvbio/utils

set -eu

#check working directory
#if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/ploscompbiol_data/crosslink_simdata" ]
#if [ "$(pwd)" != "/home/vicker/crosslink/ploscompbiol_data/crosslink_simdata" ]
if [ "$(pwd)" != "/home/vicker/ploscompbiol_data_dockerhost" ]
then
    echo unexpected working directory
    exit
fi

export BASENAME=phasing001

export MAPSIZE=500.0
export NLGS=4
export POPSIZE=200
export PROBBOTH=0.3333
export PROBMAT=0.3333
export MAPFUNC=1
export STATSDIR=phasing_stats
export TYPEERR=0.0

export REP
export DENSITY
export MAPSIZE
export ERATE
export MRATE
export FNAME
export GROUPLOD

mkdir -p ${STATSDIR}

for REP in $(seq 1 10)                               #replicates
do
    for DENSITY in 0.5 1.0 2.0 5.0                   #markers per centimorgan
    do
        for ERATE in 0.00 0.005 0.01 0.02       #error/missing rate
        do
            MRATE=${ERATE}
            FNAME=${BASENAME}_${DENSITY}_${MAPSIZE}_${ERATE}_${REP}
            
            #create test data if not already done
            if [ ! -e ${FNAME}.loc ]
            then
                create_test_map.sh     #outputs to ${FNAME}.map/loc/orig
            fi
        
            for GROUPLOD in 7 8 9 10
            do
                echo ${FNAME} ${GROUPLOD}
                #myqsub.sh $(which test_cl_typeerr.sh)
                test_cl_phasing.sh&
                #exit
            done
            
            #avoid overloading the grid engine queue / node
            while true
            do
                if [ $(ps -a | wc --lines) -gt 100 ]
                then
                    sleep 1
                else
                    break
                fi
            done
        done
    done
done
