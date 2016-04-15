#!/bin/bash

#
# run a sample polyploid data set though the basic pipeline
#

set -eu

#change this to point towards the crosslink directory containing create_map, sample_map etc
CROSSLINK_PATH=/home/vicker/rjv_mnt/cluster/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${CROSSLINK_PATH}/sample_data

rm -rf *

#create a map
MAP_SIZE=500         #500cM total map length
MARKER_DENSITY=1.0   #average of 1 marker per centimorgan
NUMB_LGS=10          #divided map into 10 equally sized linkage groups
PROB_HK=0.333        #equal probabilities of the three marker types
PROB_LM=0.333

create_map --output-file=sample.map\
           --numb-lgs=${NUMB_LGS}\
           --map-size=${MAP_SIZE}\
           --marker-density=${MARKER_DENSITY}\
           --prob-both=${PROB_HK}\
           --prob-maternal=${PROB_LM}
           
#sample data from it
POP_SIZE=200            #simulate genotypes from 200 progeny
PROB_MISSING=0.01       #1% missing data
PROB_ERROR=0.01         #1% genotyping errors

mkdir orig
sample_map --input-file=sample.map\
           --output-file=sample.loc\
           --orig-dir=orig\
           --samples=${POP_SIZE}\
           --prob-missing=${PROB_MISSING}\
           --prob-error=${PROB_ERROR}


N_CROSSMARKERS=5        #create 5 cross-linkage group markers
PROB_TYPE_ERR=0.05      #5% marker typing errors (ie confusing lmxll with nnxnp)

create_type_errors.py\
    sample.map\
    sample.loc\
    ${N_CROSSMARKERS}\
    ${PROB_TYPE_ERR}\
    > sample2.loc

#group
MINLOD=6.0       #form linkage groups using this linkage LOD threshold
IGNORECXR=1      #ignore cxr and rxc coupling between hkxhk markers during linkage group formation
MATPATLOD=10.0   #correct marker typing errors using this LOD threshold
KNN=3            #imputing missing values to the most common of the three nearest markers

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

#grouping accuracy
echo grouping accuracy $(calc_grouping_accuracy.py 'orig/*.orig' 'groups/*.loc')

#phasing accuracy
echo phasing accuracy $(calc_phasing_accuracy.py 'orig/*.orig' 'groups/*.loc')

#knn imputation accuracy
echo knn imputation accuracy $(calc_imputation_accuracy.py 'orig/*.orig' sample.loc 'groups/*.loc')

#make initial map
MINCOUNT=8

rm -rf init
mkdir -p init
for x in groups/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=init/$(basename ${x})\
        --map=init/$(basename ${x/loc/map})\
        --log=init/$(basename ${x/loc/log})\
        --ga_gibbs_cycles=3\
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

#filter out cross linkage group markers
cat init/*.log | grep homeo | cut -d ' ' -f 2 > crossmarkers
cat ./sample2.loc | grep -vf crossmarkers > sample3.loc

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

#count uncorrected crossmarkers and false corrections
UNCORRECTEDX=$(cat crossmarkers_list | grep -vf crossmarkers | wc --lines)
FALSECORRX=$(cat crossmarkers | grep -vf crossmarkers_list | wc --lines)
echo crossmarkers uncorrected: ${UNCORRECTEDX} false corrections: ${FALSECORRX}

#count uncorrected typing errors and number of false corrections
cat group2.log | grep 'type corrected' | awk '{print $4}' > type_corrected
UNCORRECTED=$(cat typeerrmarkers_list | grep -vf type_corrected | wc --lines)
FALSECORR=$(cat type_corrected | grep -vf typeerrmarkers_list | wc --lines)
echo typing errors uncorrected: ${UNCORRECTED} false corrections: ${FALSECORR}

#grouping accuracy
echo grouping accuracy $(calc_grouping_accuracy.py 'orig/*.orig' 'groups2/*.loc')

#phasing accuracy
echo phasing accuracy $(calc_phasing_accuracy.py 'orig/*.orig' 'groups2/*.loc')

#knn imputation accuracy
echo knn imputation accuracy $(calc_imputation_accuracy.py 'orig/*.orig' sample.loc 'groups2/*.loc')

#make final map
rm -rf final
mkdir -p final
for x in groups2/*.loc
do
    crosslink_map\
        --inp=${x}\
        --out=final/$(basename ${x})\
        --map=final/$(basename ${x/loc/map})\
        --ga_gibbs_cycles=20\
        --ga_optimise_meth=0 &
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
