#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# run a sample polyploid data set though the basic pipeline
# scenario based on RGxHA data
#

set -eu

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/rjv_mnt/cluster/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/sample_data

#remove everything
if [ "$(pwd)" != '/home/vicker/crosslink/ploscompbiol_data/simdata' ]
then
    echo wrong working directory
    exit
fi

#group
MINLOD=6.0       #form linkage groups using this linkage LOD threshold
IGNORECXR=1      #ignore cxr and rxc coupling between hkxhk markers during linkage group formation
MATPATLOD=10.0   #correct marker typing errors using this LOD threshold
KNN=3            #imputing missing values to the most common of the three nearest markers

#init mapping
MINCOUNT=8
INIT_CYCLES=3

#final mapping
FINAL_CYCLES=5
FINAL_METH=0

echo
echo initial grouping...

rm -rf groups
mkdir -p groups
crosslink_group\
        --inp=sample2.loc\
        --log=group.log\
        --outbase=groups/\
        --mapbase=groups/\
        --min_lod=${MINLOD}\
        --ignore_cxr=${IGNORECXR}\
        --matpat_lod=${MATPATLOD}\
        --knn=${KNN}

#count uncorrected typing errors and number of false corrections
echo typing error correction accuracy $(calc_typeerr_accuracy.py typeerrmarkers_list group.log) for $(cat typeerrmarkers_list | wc --lines) errors

#grouping accuracy
echo grouping accuracy $(calc_grouping_accuracy.py 'orig/*.orig' 'groups/*.loc')

#phasing accuracy
echo phasing accuracy $(calc_phasing_accuracy.py 'orig/*.orig' 'groups/*.loc')

#knn imputation accuracy
echo knn imputation accuracy $(calc_imputation_accuracy.py 'orig/*.orig' sample.loc 'groups/*.loc')

#hk imputation accuracy
echo mapping accuracy $(calc_mapping_accuracy.sh sample.map 'groups/*.map')

#make initial map

echo
echo initial mapping...

rm -rf init
mkdir -p init
for x in groups/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=init/$(basename ${x})\
        --map=init/$(basename ${x/loc/map})\
        --log=init/$(basename ${x/loc/log})\
        --ga_gibbs_cycles=${INIT_CYCLES}\
        --homeo_mincount=${MINCOUNT}\
        &
done

echo -n waiting for jobs to finish
while [ "$(ps | grep crosslink_map | wc --lines)" != "0" ]
do
    echo -n .
    sleep 1
done
echo ' done'

#hk imputation accuracy
echo hk imputation accuracy $(calc_hk_accuracy.py 'orig/*.orig' 'init/*.loc')

#mapping accuracy
echo mapping accuracy $(calc_mapping_accuracy.sh sample.map 'init/*.map')


#filter out cross linkage group markers
cat init/*.log | grep homeo | cut -d ' ' -f 2 > crossmarkers
cat ./sample2.loc | grep -vf crossmarkers > sample3.loc

#cross lg marker detection accuracy
echo crosslg detection accuracy $(calc_crosslg_accuracy.py crossmarkers_list 'init/*.log') for $(cat crossmarkers_list | wc --lines) errors

echo
echo final grouping...

#make final groups
rm -rf groups2
mkdir -p groups2
crosslink_group\
        --inp=sample3.loc\
        --log=group2.log\
        --outbase=groups2/\
        --mapbase=groups2/\
        --min_lod=${MINLOD}\
        --ignore_cxr=${IGNORECXR}\
        --matpat_lod=${MATPATLOD}\
        --knn=${KNN}

#quantify typing error correction accuracy
echo typing error correction accuracy $(calc_typeerr_accuracy.py typeerrmarkers_list group2.log) for $(cat typeerrmarkers_list | wc --lines) errors

#grouping accuracy
echo grouping accuracy $(calc_grouping_accuracy.py 'orig/*.orig' 'groups2/*.loc')

#phasing accuracy
echo phasing accuracy $(calc_phasing_accuracy.py 'orig/*.orig' 'groups2/*.loc')

#knn imputation accuracy
echo knn imputation accuracy $(calc_imputation_accuracy.py 'orig/*.orig' sample.loc 'groups2/*.loc')

#hk imputation accuracy
echo mapping accuracy $(calc_mapping_accuracy.sh sample.map 'groups2/*.map')

echo
echo final mapping...


#make final map
rm -rf final
mkdir -p final
for x in groups2/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=final/$(basename ${x})\
        --map=final/$(basename ${x/loc/map})\
        --ga_gibbs_cycles=${FINAL_CYCLES}\
        --ga_optimise_meth=${FINAL_METH} &
done

echo -n waiting for jobs to finish
while [ "$(ps | grep crosslink_map | wc --lines)" != "0" ]
do
    echo -n .
    sleep 1
done
echo ' done'

#hk imputation accuracy
echo hk imputation accuracy $(calc_hk_accuracy.py 'orig/*.orig' 'final/*.loc')

#hk imputation accuracy
echo mapping accuracy $(calc_mapping_accuracy.sh sample.map 'final/*.map')
