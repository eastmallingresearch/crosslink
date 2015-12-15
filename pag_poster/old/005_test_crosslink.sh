#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

mkdir -p stats
mkdir -p tmp

RUN_SMALLMAP=1

if [ "${RUN_SMALLMAP}" == "1" ]
then
    #test on a small map: 1 LG, 50 centimorgan, 30 markers
    rm -f stats/smallmap.csv
    
    #list of mapping programs
    echo crosslink >  tmp/proglist
    echo tmap      >> tmp/proglist
    echo lepmap2   >> tmp/proglist
    echo onemap    >> tmp/proglist
    
    #for each replicate
    for FNAME in test_maps_small/test???.loc
    do
        #randomise order of program testing each replicate
        cat tmp/proglist | shuf > tmp/proglist_random
    
        echo ${FNAME}
        cat ${FNAME} > /dev/null #try to cache the data to prevent the first program from taking longer to load
        
        cat tmp/proglist_random |\
        while read PROG
        do
            echo ${PROG} 
            #START_SECS=$SECONDS
            #SCORE=$(test_crosslink_small.sh)
            #TOTAL_SECS=$(($SECONDS - $START_SECS))
            #echo ${SCORE} ${TOTAL_SECS}
        done
    done #>> stats/smallmap.csv
fi
