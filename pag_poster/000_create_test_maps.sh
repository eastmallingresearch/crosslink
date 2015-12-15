#!/bin/bash

#
# create the test maps
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

RUN_SMALL=0
RUN_MEDIUM=0
RUN_1PC_ERROR=0
RUN_2PC_ERROR=0
RUN_5PC_ERROR=0
RUN_CONV2LEPMAP=1

if [ "${RUN_CONV2LEPMAP}" == "1" ]
then
    for FNAME in test_maps_small/test???.loc test_maps_?pc/test???.loc
    do
        STEMNAME=${FNAME/.loc/}
        echo ${STEMNAME}
        #convert to lepmap format
        convert2lepmap.py ${STEMNAME}.loc > ${STEMNAME}.lepmap.tmp
        transpose_tsv.py ${STEMNAME}.lepmap.tmp > ${STEMNAME}.lepmap
    done
fi

if [ "${RUN_5PC_ERROR}" == "1" ]
then
    #small test map
    OUTDIR=test_maps_5pc
    REPLICATES=40
    
    NLGS=1
    LGSIZE=50
    NMARKERS=30
    PROB_HK=0.333
    PROB_LM=0.5
    POPSIZE=200
    MISSING=0.05
    ERROR=0.05
    MAPFUNC=1

    rm -rf ${OUTDIR}
    mkdir -p ${OUTDIR}

    for REP in $(seq 1 ${REPLICATES})
    do
        FNAME=$(printf "test%03d" ${REP})

        #create map with randomly placed markers
        create_map --out ${OUTDIR}/${FNAME}.map\
                   --nmarkers ${NMARKERS}\
                   --nlgs ${NLGS}\
                   --lg_size ${LGSIZE}\
                   --prob_hk ${PROB_HK}\
                   --prob_lm ${PROB_LM}\
                   --hideposn 1
                   
        #simulate genotyping data from the markers
        sample_map --inp ${OUTDIR}/${FNAME}.map\
                   --out ${OUTDIR}/${FNAME}.loc\
                   --orig ${OUTDIR}/${FNAME}_orig.loc\
                   --hide_hk_inheritance 1\
                   --randomise_order 1\
                   --nind ${POPSIZE}\
                   --prob_missing ${MISSING}\
                   --prob_error ${ERROR}\
                   --map_func ${MAPFUNC}
                   
        #convert to tmap format
        echo "data type outbred"      >  ${OUTDIR}/${FNAME}.loc.tmap
        echo "${POPSIZE} ${NMARKERS}" >> ${OUTDIR}/${FNAME}.loc.tmap
        tail -n +5 ${OUTDIR}/${FNAME}.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> ${OUTDIR}/${FNAME}.loc.tmap
            
        #convert to lepmap format
        #convert2lepmap.py ${OUTDIR}/${FNAME}.loc\
        #    > ${OUTDIR}/${FNAME}.loc.tmp
        #transpose_tsv.py ${OUTDIR}/${FNAME}.loc.tmp\
        #    > ${OUTDIR}/${FNAME}.loc.lepmap
        
        #convert to onemap format
        convert2onemap.py ${OUTDIR}/${FNAME}.loc\
            > ${OUTDIR}/${FNAME}.loc.onemap
                   
        #create file listing only marker names and cm pos in correct order 
        tail -n +2 ${OUTDIR}/${FNAME}.map\
            | awk '{print $1, $5}'\
            > ${OUTDIR}/${FNAME}.map.order
    done
fi

if [ "${RUN_2PC_ERROR}" == "1" ]
then
    #small test map
    OUTDIR=test_maps_2pc
    REPLICATES=40
    
    NLGS=1
    LGSIZE=50
    NMARKERS=30
    PROB_HK=0.333
    PROB_LM=0.5
    POPSIZE=200
    MISSING=0.02
    ERROR=0.02
    MAPFUNC=1

    rm -rf ${OUTDIR}
    mkdir -p ${OUTDIR}

    for REP in $(seq 1 ${REPLICATES})
    do
        FNAME=$(printf "test%03d" ${REP})

        #create map with randomly placed markers
        create_map --out ${OUTDIR}/${FNAME}.map\
                   --nmarkers ${NMARKERS}\
                   --nlgs ${NLGS}\
                   --lg_size ${LGSIZE}\
                   --prob_hk ${PROB_HK}\
                   --prob_lm ${PROB_LM}\
                   --hideposn 1
                   
        #simulate genotyping data from the markers
        sample_map --inp ${OUTDIR}/${FNAME}.map\
                   --out ${OUTDIR}/${FNAME}.loc\
                   --orig ${OUTDIR}/${FNAME}_orig.loc\
                   --hide_hk_inheritance 1\
                   --randomise_order 1\
                   --nind ${POPSIZE}\
                   --prob_missing ${MISSING}\
                   --prob_error ${ERROR}\
                   --map_func ${MAPFUNC}
                   
        #convert to tmap format
        echo "data type outbred"      >  ${OUTDIR}/${FNAME}.loc.tmap
        echo "${POPSIZE} ${NMARKERS}" >> ${OUTDIR}/${FNAME}.loc.tmap
        tail -n +5 ${OUTDIR}/${FNAME}.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> ${OUTDIR}/${FNAME}.loc.tmap
            
        #convert to lepmap format
        #convert2lepmap.py ${OUTDIR}/${FNAME}.loc\
        #    > ${OUTDIR}/${FNAME}.loc.tmp
        #transpose_tsv.py ${OUTDIR}/${FNAME}.loc.tmp\
        #    > ${OUTDIR}/${FNAME}.loc.lepmap
        
        #convert to onemap format
        convert2onemap.py ${OUTDIR}/${FNAME}.loc\
            > ${OUTDIR}/${FNAME}.loc.onemap
                   
        #create file listing only marker names and cm pos in correct order 
        tail -n +2 ${OUTDIR}/${FNAME}.map\
            | awk '{print $1, $5}'\
            > ${OUTDIR}/${FNAME}.map.order
    done
fi

if [ "${RUN_1PC_ERROR}" == "1" ]
then
    #small test map
    OUTDIR=test_maps_1pc
    REPLICATES=40
    
    NLGS=1
    LGSIZE=50
    NMARKERS=30
    PROB_HK=0.333
    PROB_LM=0.5
    POPSIZE=200
    MISSING=0.01
    ERROR=0.01
    MAPFUNC=1

    rm -rf ${OUTDIR}
    mkdir -p ${OUTDIR}

    for REP in $(seq 1 ${REPLICATES})
    do
        FNAME=$(printf "test%03d" ${REP})

        #create map with randomly placed markers
        create_map --out ${OUTDIR}/${FNAME}.map\
                   --nmarkers ${NMARKERS}\
                   --nlgs ${NLGS}\
                   --lg_size ${LGSIZE}\
                   --prob_hk ${PROB_HK}\
                   --prob_lm ${PROB_LM}\
                   --hideposn 1
                   
        #simulate genotyping data from the markers
        sample_map --inp ${OUTDIR}/${FNAME}.map\
                   --out ${OUTDIR}/${FNAME}.loc\
                   --orig ${OUTDIR}/${FNAME}_orig.loc\
                   --hide_hk_inheritance 1\
                   --randomise_order 1\
                   --nind ${POPSIZE}\
                   --prob_missing ${MISSING}\
                   --prob_error ${ERROR}\
                   --map_func ${MAPFUNC}
                   
        #convert to tmap format
        echo "data type outbred"      >  ${OUTDIR}/${FNAME}.loc.tmap
        echo "${POPSIZE} ${NMARKERS}" >> ${OUTDIR}/${FNAME}.loc.tmap
        tail -n +5 ${OUTDIR}/${FNAME}.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> ${OUTDIR}/${FNAME}.loc.tmap
            
        #convert to lepmap format
        #convert2lepmap.py ${OUTDIR}/${FNAME}.loc\
        #    > ${OUTDIR}/${FNAME}.loc.tmp
        #transpose_tsv.py ${OUTDIR}/${FNAME}.loc.tmp\
        #    > ${OUTDIR}/${FNAME}.loc.lepmap
        
        #convert to onemap format
        convert2onemap.py ${OUTDIR}/${FNAME}.loc\
            > ${OUTDIR}/${FNAME}.loc.onemap
                   
        #create file listing only marker names and cm pos in correct order 
        tail -n +2 ${OUTDIR}/${FNAME}.map\
            | awk '{print $1, $5}'\
            > ${OUTDIR}/${FNAME}.map.order
    done
fi

if [ "${RUN_MEDIUM}" == "1" ]
then
    #small test map
    OUTDIR=test_maps_medium
    REPLICATES=40
    
    NLGS=1
    LGSIZE=250
    NMARKERS=150
    PROB_HK=0.333
    PROB_LM=0.5
    POPSIZE=200
    MISSING=0.0
    ERROR=0.0
    MAPFUNC=1

    rm -rf ${OUTDIR}
    mkdir -p ${OUTDIR}

    for REP in $(seq 1 ${REPLICATES})
    do
        FNAME=$(printf "test%03d" ${REP})

        #create map with randomly placed markers
        create_map --out ${OUTDIR}/${FNAME}.map\
                   --nmarkers ${NMARKERS}\
                   --nlgs ${NLGS}\
                   --lg_size ${LGSIZE}\
                   --prob_hk ${PROB_HK}\
                   --prob_lm ${PROB_LM}\
                   --hideposn 1
                   
        #simulate genotyping data from the markers
        sample_map --inp ${OUTDIR}/${FNAME}.map\
                   --out ${OUTDIR}/${FNAME}.loc\
                   --orig ${OUTDIR}/${FNAME}_orig.loc\
                   --hide_hk_inheritance 1\
                   --randomise_order 1\
                   --nind ${POPSIZE}\
                   --prob_missing ${MISSING}\
                   --prob_error ${ERROR}\
                   --map_func ${MAPFUNC}
                   
        #convert to tmap format
        echo "data type outbred"      >  ${OUTDIR}/${FNAME}.loc.tmap
        echo "${POPSIZE} ${NMARKERS}" >> ${OUTDIR}/${FNAME}.loc.tmap
        tail -n +5 ${OUTDIR}/${FNAME}.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> ${OUTDIR}/${FNAME}.loc.tmap
            
        #convert to lepmap format
        #convert2lepmap.py ${OUTDIR}/${FNAME}.loc\
        #    > ${OUTDIR}/${FNAME}.loc.tmp
        #transpose_tsv.py ${OUTDIR}/${FNAME}.loc.tmp\
        #    > ${OUTDIR}/${FNAME}.loc.lepmap
        
        #convert to onemap format
        convert2onemap.py ${OUTDIR}/${FNAME}.loc\
            > ${OUTDIR}/${FNAME}.loc.onemap
                   
        #create file listing only marker names and cm pos in correct order 
        tail -n +2 ${OUTDIR}/${FNAME}.map\
            | awk '{print $1, $5}'\
            > ${OUTDIR}/${FNAME}.map.order
    done
fi

if [ "${RUN_SMALL}" == "1" ]
then
    #small test map
    OUTDIR=test_maps_small
    REPLICATES=40
    
    NLGS=1
    LGSIZE=50
    NMARKERS=30
    PROB_HK=0.333
    PROB_LM=0.5
    POPSIZE=200
    MISSING=0.0
    ERROR=0.0
    MAPFUNC=1

    rm -rf ${OUTDIR}
    mkdir -p ${OUTDIR}

    for REP in $(seq 1 ${REPLICATES})
    do
        FNAME=$(printf "test%03d" ${REP})

        #create map with randomly placed markers
        create_map --out ${OUTDIR}/${FNAME}.map\
                   --nmarkers ${NMARKERS}\
                   --nlgs ${NLGS}\
                   --lg_size ${LGSIZE}\
                   --prob_hk ${PROB_HK}\
                   --prob_lm ${PROB_LM}\
                   --hideposn 1
                   
        #simulate genotyping data from the markers
        sample_map --inp ${OUTDIR}/${FNAME}.map\
                   --out ${OUTDIR}/${FNAME}.loc\
                   --orig ${OUTDIR}/${FNAME}_orig.loc\
                   --hide_hk_inheritance 1\
                   --randomise_order 1\
                   --nind ${POPSIZE}\
                   --prob_missing ${MISSING}\
                   --prob_error ${ERROR}\
                   --map_func ${MAPFUNC}
                   
        #convert to tmap format
        echo "data type outbred"      >  ${OUTDIR}/${FNAME}.loc.tmap
        echo "${POPSIZE} ${NMARKERS}" >> ${OUTDIR}/${FNAME}.loc.tmap
        tail -n +5 ${OUTDIR}/${FNAME}.loc\
            | sed 's/ {..}//g'\
            | tr 'lmnphk' 'ababab'\
            >> ${OUTDIR}/${FNAME}.loc.tmap
            
        #convert to lepmap format
        #convert2lepmap.py ${OUTDIR}/${FNAME}.loc\
        #    > ${OUTDIR}/${FNAME}.loc.tmp
        #transpose_tsv.py ${OUTDIR}/${FNAME}.loc.tmp\
        #    > ${OUTDIR}/${FNAME}.loc.lepmap
        
        #convert to onemap format
        convert2onemap.py ${OUTDIR}/${FNAME}.loc\
            > ${OUTDIR}/${FNAME}.loc.onemap
                   
        #create file listing only marker names and cm pos in correct order 
        tail -n +2 ${OUTDIR}/${FNAME}.map\
            | awk '{print $1, $5}'\
            > ${OUTDIR}/${FNAME}.map.order
    done
fi
