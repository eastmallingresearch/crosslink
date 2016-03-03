#!/bin/bash

#
# test crosslink_group on simulated data
# optimse grouping
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/simdata

#export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/scripts
#export PATH=${PATH}:/home/vicker/rjv_mnt/cluster/git_repos/crosslink/simdata

set -eu

#check working directory
#if [ "$(pwd)" != "/home/vicker/rjv_mnt/cluster/crosslink/ploscompbiol_data/crosslink_simdata" ]
if [ "$(pwd)" != "/home/vicker/crosslink/ploscompbiol_data/crosslink_simdata" ]
then
    echo unexpected working directory
    exit
fi

export BASENAME=grouping001

export MAPSIZE=500.0
export NLGS=4
export TYPEERR=0.0
export POPSIZE=200
export PROBBOTH=0.3333
export PROBMAT=0.3333
export MAPFUNC=1
export STATSDIR=${BASENAME}stats

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
        for ERATE in 0.00 0.005 0.01 0.02 0.05       #error/missing rate
        do
            for MRATE in 0.00 0.005 0.01 0.02 0.05   #error/missing rate
            do
                FNAME=${BASENAME}_${DENSITY}_${MAPSIZE}_${ERATE}_${MRATE}_${REP}
                
                #create test data if not already done
                if [ ! -e ${FNAME}.loc ]
                then
                    echo ${FNAME}
                    create_test_map.sh     #outputs to ${FNAME}.map/loc/orig
                fi
            
                for GROUPLOD in 2 3 4 5 6 7 8 9 10
                do
                    test_cl_grouping.sh&
                done
                
                #wait for stuff to finish
                while true
                do
                    if [ $(ps -a|wc --lines) -gt 300 ]
                    then
                        sleep 1
                    else
                        break
                    fi
                done
            done
        done
    done
done
