#Crosslink, Copyright (C) 2016  NIAB EMR

#
# recalculate mapping accuracy as three different values
# run from ~/crosslink/ploscompbiol_data/mdensity_simdata
#

set -eu

source ~/rjv_bashrc

export PATH=${CROSSLINK_PATH}/compare_progs:${PATH}

for OUTPUTDIR in [0-9]*
do
    if [ ! -e ${OUTPUTDIR}/score ] ; then continue ; fi

    cd ${OUTPUTDIR}

    PROG=$(cat score | cut -d' ' -f1)
    SAMPLEDIR=$(cat score | cut -d' ' -f2)
    DENSITY=$(echo ${SAMPLEDIR} | cut -d/ -f2 | cut -d_ -f1)
    TIMEUSER=$(cat score | cut -d' ' -f4)
    TIMESYS=$(cat score | cut -d' ' -f5)

    cat ../${SAMPLEDIR}/sample.map | grep -v -e '^#' | awk -v OFS=',' '{print $1,$4,$5}' > tmprefmap.csv

    echo -n "${PROG} ${DENSITY} ${TIMEUSER} ${TIMESYS} " > score2
    mapping_accuracy_1lg.py tmprefmap.csv final.csv >> score2
    
    cd ..
done

cat */score2  > figs/mdensity_4way

cat figs/joinmap_stats |
while read line
do
    PROG=$(echo ${line} | cut -d' ' -f1)
    DENSITY=$(echo ${line} | cut -d' ' -f2)
    TIMESECS=$(echo ${line} | cut -d' ' -f3)
    #MEM=$(echo line | cut -d' ' -f4)
    SAMPLEDIR=$(echo ${line} | cut -d' ' -f5)
    MAPFILE=figs/joinmap_results/den${DENSITY}.map
    
    cat sample_data/${SAMPLEDIR}/sample.map | grep -v -e '^#' | awk -v OFS=',' '{print $1,$4,$5}' > tmprefmap.csv
    cat ${MAPFILE} | grep -e '^M' | awk -v OFS=',' '{print $1,1,$2}' > tmp_joinmap_${DENSITY}.csv

    echo -n "${PROG} ${DENSITY} ${TIMESECS} 0 "                      >> figs/mdensity_4way
    mapping_accuracy_1lg.py tmprefmap.csv tmp_joinmap_${DENSITY}.csv >> figs/mdensity_4way

done
