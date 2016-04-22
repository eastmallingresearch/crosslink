#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# run a sample diploid data set though the basic pipeline
#

set -eu

#change this to point towards the crosslink install directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink
export PATH=${CROSSLINK_PATH}/scripts:${CROSSLINK_PATH}/bin:${PATH}

#check we can find the crosslink files
if [ ! -f ${CROSSLINK_PATH}/bin/crosslink_group ]
then
    echo "Unable to find the Crosslink files, have you set the CROSSLINK_PATH variable correctly?"
    exit 1
fi

#create a map specification file
create_map --output-file=sample.spec --numb-lgs=28 --map-size=2000 --marker-density=2.0 --prob-both=0.28 --prob-maternal=0.36
           
#create sample dataset, including missing genotypes and simple genotyping errors
sample_map --input-file=sample.spec --output-file=sample.loc --samples=162 --prob-missing=0.007 --prob-error=0.01

#form linkage groups, phase, impute missing data
crosslink_group --inp=sample.loc --outbase=group --min_lod=10.0 --knn=3

#make final marker ordering, calculate multipoint map positions
for fname in group???.loc
do
    echo ${fname}...
    outname=${fname/group/final}
    crosslink_map --inp=${fname} --out=${outname} --map=${outname/loc/map}
done
