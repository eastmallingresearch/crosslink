#!/bin/bash

#
# test crosslink on simulated data
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

mkdir -p stats
mkdir -p tmp

RUN_SMALLMAP=0
RUN_MEDIUMMAP=0
RUN_1PC_ERROR=0
RUN_2PC_ERROR=0
RUN_5PC_ERROR=0


if [ "${RUN_5PC_ERROR}" == "1" ]
then
    PRGLIST=tmp/proglist_${RANDOM}
    DATADIR=test_maps_5pc
    STATSFILE=stats/5pcerrormap.csv

    #test on a medium map
    rm -f ${STATSFILE}
    
    #list of mapping programs
    echo -n ""      >  ${PRGLIST}
    echo crosslink  >> ${PRGLIST}
    echo tmap       >> ${PRGLIST}
    #echo lepmap2   >> ${PRGLIST}
    echo onemap1    >> ${PRGLIST}
    #echo onemap2   >> ${PRGLIST}
    
    #for each replicate
    for FNAME in ${DATADIR}/test???.loc
    do
        BASENAME=$(basename ${FNAME/.loc/})
    
        #randomise order of program testing
        cat ${PRGLIST} | shuf > ${PRGLIST}_random
        
        #try to cache the data to prevent the first program from taking longer to load
        cat ${FNAME} > /dev/null
        cat ${FNAME}.tmap > /dev/null
        cat ${FNAME}.onemap > /dev/null
        
        cat ${PRGLIST}_random |\
        while read PROG
        do
            START_SECS=$SECONDS
            test_${PROG}_small.sh ${FNAME} ${PROG}_${DATADIR}
            TOTAL_SECS=$(($SECONDS - $START_SECS))
            SCORE=$(calc_spearmans.py\
                        ${FNAME/.loc/}.map.order\
                        ${PROG}_${DATADIR}/${BASENAME}.order)
            echo ${FNAME} ${PROG} ${SCORE} ${TOTAL_SECS} >> ${STATSFILE}
        done
    done
fi

if [ "${RUN_2PC_ERROR}" == "1" ]
then
    #test on a medium map
    rm -f stats/2pcerrormap.csv
    
    #list of mapping programs
    echo -n ""      > tmp/proglist3
    echo crosslink  >>  tmp/proglist3
    echo tmap      >> tmp/proglist3
    #echo lepmap2   >> tmp/proglist3
    echo onemap1    >> tmp/proglist3
    #echo onemap2    >> tmp/proglist3
    
    #for each replicate
    for FNAME in test_maps_2pc/test???.loc
    do
        BASENAME=$(basename ${FNAME/.loc/})
    
        #randomise order of program testing
        cat tmp/proglist3 | shuf > tmp/proglist3_random
        
        #try to cache the data to prevent the first program from taking longer to load
        cat ${FNAME} > /dev/null
        cat ${FNAME}.tmap > /dev/null
        cat ${FNAME}.onemap > /dev/null
        
        cat tmp/proglist3_random |\
        while read PROG
        do
            START_SECS=$SECONDS
            test_${PROG}_small.sh ${FNAME} ${PROG}_2pcerr
            TOTAL_SECS=$(($SECONDS - $START_SECS))
            SCORE=$(calc_spearmans.py\
                        ${FNAME/.loc/}.map.order\
                        ${PROG}_2pcerr/${BASENAME}.order)
            echo ${FNAME} ${PROG} ${SCORE} ${TOTAL_SECS} >> stats/2pcerrormap.csv
        done
    done
fi

if [ "${RUN_1PC_ERROR}" == "1" ]
then
    #test on a medium map
    rm -f stats/1pcerrormap.csv
    
    #list of mapping programs
    echo -n ""      > tmp/proglist2
    echo crosslink  >>  tmp/proglist2
    echo tmap      >> tmp/proglist2
    #echo lepmap2   >> tmp/proglist2
    echo onemap1    >> tmp/proglist2
    #echo onemap2    >> tmp/proglist2
    
    #for each replicate
    for FNAME in test_maps_1pc/test???.loc
    do
        BASENAME=$(basename ${FNAME/.loc/})
    
        #randomise order of program testing
        cat tmp/proglist2 | shuf > tmp/proglist2_random
        
        #try to cache the data to prevent the first program from taking longer to load
        cat ${FNAME} > /dev/null
        cat ${FNAME}.tmap > /dev/null
        cat ${FNAME}.onemap > /dev/null
        
        cat tmp/proglist2_random |\
        while read PROG
        do
            START_SECS=$SECONDS
            test_${PROG}_small.sh ${FNAME} ${PROG}_1pcerr
            TOTAL_SECS=$(($SECONDS - $START_SECS))
            SCORE=$(calc_spearmans.py\
                        ${FNAME/.loc/}.map.order\
                        ${PROG}_1pcerr/${BASENAME}.order)
            echo ${FNAME} ${PROG} ${SCORE} ${TOTAL_SECS} >> stats/1pcerrormap.csv
        done
    done
fi

if [ "${RUN_MEDIUMMAP}" == "1" ]
then
    #test on a medium map
    rm -f stats/mediummap.csv
    
    #list of mapping programs
    echo -n ""      > tmp/proglist
    echo crosslink  >>  tmp/proglist
    echo tmap      >> tmp/proglist
    #echo lepmap2   >> tmp/proglist
    echo onemap1    >> tmp/proglist
    #echo onemap2    >> tmp/proglist
    
    #for each replicate
    for FNAME in test_maps_medium/test???.loc
    do
        BASENAME=$(basename ${FNAME/.loc/})
    
        #randomise order of program testing
        cat tmp/proglist | shuf > tmp/proglist_random
        
        #try to cache the data to prevent the first program from taking longer to load
        cat ${FNAME} > /dev/null
        cat ${FNAME}.tmap > /dev/null
        cat ${FNAME}.onemap > /dev/null
        
        cat tmp/proglist_random |\
        while read PROG
        do
            START_SECS=$SECONDS
            test_${PROG}_small.sh ${FNAME} ${PROG}_medium
            TOTAL_SECS=$(($SECONDS - $START_SECS))
            SCORE=$(calc_spearmans.py\
                        ${FNAME/.loc/}.map.order\
                        ${PROG}_medium/${BASENAME}.order)
            echo ${FNAME} ${PROG} ${SCORE} ${TOTAL_SECS} >> stats/mediummap.csv
        done
    done
fi

if [ "${RUN_SMALLMAP}" == "1" ]
then
    #test on a small map
    rm -f stats/smallmap.csv
    
    #list of mapping programs
    echo -n ""      > tmp/proglist
    echo crosslink  >>  tmp/proglist
    echo tmap      >> tmp/proglist
    #echo lepmap2   >> tmp/proglist
    echo onemap1    >> tmp/proglist
    #echo onemap2    >> tmp/proglist
    
    #for each replicate
    for FNAME in test_maps_small/test???.loc
    do
        BASENAME=$(basename ${FNAME/.loc/})
    
        #randomise order of program testing
        cat tmp/proglist | shuf > tmp/proglist_random
        
        #try to cache the data to prevent the first program from taking longer to load
        cat ${FNAME} > /dev/null
        cat ${FNAME}.tmap > /dev/null
        cat ${FNAME}.onemap > /dev/null
        
        cat tmp/proglist_random |\
        while read PROG
        do
            START_SECS=$SECONDS
            test_${PROG}_small.sh ${FNAME} ${PROG}_small
            TOTAL_SECS=$(($SECONDS - $START_SECS))
            SCORE=$(calc_spearmans.py\
                        ${FNAME/.loc/}.map.order\
                        ${PROG}_small/${BASENAME}.order)
            echo ${FNAME} ${PROG} ${SCORE} ${TOTAL_SECS} >> stats/smallmap.csv
        done
    done
fi
