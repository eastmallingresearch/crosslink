#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################
#
# example pipeline to build a map from the Redgauntlet x Hapil sample data
# using Crosslink's helper scripts
# note: this is not the full pipeline used to build the final published map
# but is a simplified version to demonstrate the use of the helper scripts
#
# the main difference is that the produced linkage group names do not follow the
# conventions of the Holiday x Korona map and the ordering produced is
# slightly different to the full RGxHA map
#
# this pipeline does not require any files outside the crosslink repostory
# except IStraw90.r1.ps2snp_map.ps from http://media.affymetrix.com/analysis/downloads/lf/genotyping/IStraw90/
# if the map is to be compared to other IStraw90 maps
#
################################################################################

#check CROSSLINK_PATH is set
if [ -z "${CROSSLINK_PATH:-}" ]
then
    echo "Please set the variable CROSSLINK_PATH, otherwise this script cannot find the sample dataset"
    echo "for help see the crosslink manual https://github.com/eastmallingresearch/crosslink/blob/master/docs/crosslink_manual.pdf"
    echo "in the Installing Directly on Linux section"
    exit 1
fi

#check the sample data exists
if [ ! -f ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz ]
then
    echo "Could not find the sample data at ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz"
    echo "Please check the variable CROSSLINK_PATH is set correctly and the sample data are installed"
    echo "for help see the crosslink manual https://github.com/eastmallingresearch/crosslink/blob/master/docs/crosslink_manual.pdf"
    echo "in the Installing Directly on Linux section"
    exit 1
fi

#check we can find a binary
if ! crosslink_group --help > /dev/null
then
    echo "Please add the path to Crosslink's files to your PATH variable"
    echo "for help see the crosslink manual https://github.com/eastmallingresearch/crosslink/blob/master/docs/crosslink_manual.pdf"
    echo "in the Installing Directly on Linux section"
    exit 1
fi

#check we can find a helper script
if ! cl_group.sh --check
then
    echo "Please add the path to Crosslink's files to your PATH variable"
    echo "for help see the crosslink manual https://github.com/eastmallingresearch/crosslink/blob/master/docs/crosslink_manual.pdf"
    echo "in the Installing Directly on Linux section"
    exit 1
fi

set -eu

echo copy data...

#copy the configuration files
cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf ./conf          

#get a working copy of the genotype data
zcat ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz > all.loc

echo grouping...

#initial exploratory grouping
cl_group.sh   all.loc   initgrps   7.0

echo fix typing errors...

#fix maternal/paternal marker typing errors
cl_fixtypes.sh   all.loc   all.loc   conf/fixtypes.000 

echo grouping...

#exploratory grouping after fixing type errors
cl_group.sh   all.loc   fixgrps   7.0 

echo find redundant markers...

#generate list of non redundant markers
cl_findredun.sh   all.loc   all.redun   conf/findredun.000 

echo impute missing values...

#impute missing values in all markers (including redundant ones)
cl_knnimpute.sh   all.loc   all.loc   conf/knnimpute.000 

echo extract non-redundant markers...

#extract only the nonredundant imputed markers
cl_extract.sh   all.loc   all.redun   all.uniq 

echo grouping...

#form linkage groups
cl_group.sh   all.uniq   uniqgrps   7.0 

echo phasing...

#force phasing to complete down to a LOD of zero, even for falsely joined groups
cl_phase.sh   uniqgrps   phasegrps 

echo detect cross linkage group markers...

#detect cross linkage group markers
cl_detect_crosslg.sh   phasegrps   crosslg_markers   conf/detectcrosslg.000 

#exit

#filter out cross linkage group markers
cl_removemarkers.sh   all.uniq   filt.uniq   crosslg_markers

echo grouping...

#form linkage groups
cl_group.sh   filt.uniq   filtgrps   7.0 

echo phasing...

#force phasing to complete
cl_phase.sh   filtgrps   filtgrps 

#manually specify another cross linkage group marker
echo 'PHR11-89834490' >> crosslg_markers

echo remove cross linkage group markers...

#filter out cross linkage group markers
cl_removemarkers.sh   filt.uniq   filt.uniq   crosslg_markers

echo group...

#form linkage groups
cl_group.sh   filt.uniq   filtgrps2   7.0

echo phase...

#force phasing to complete
cl_phase.sh   filtgrps2   filtgrps2

echo finalise order...

#produce final map order
cl_order_hkimpute.sh   filtgrps2   finalgrps   conf/orderhkimpute.000

echo finalise map positions...

#calc map positions
cl_mappos.sh   finalgrps   finalgrps 

echo reinsert redundant loci...

#reinsert redundant markers into genotype files
cl_reinsert_loc.sh   finalgrps   all.loc   all.redun   finalredun   conf/reinsert.000 

#reinsert redundant markers into map files
cl_reinsert_map.sh   finalgrps   all.redun   finalredun

echo generate csv map file...

#flatten map into single csv file
cl_map2csv.sh finalredun probesetid_map.csv

##uncomment the next two lines to compare to other maps by converting marker names into canonical Affymetrix SNP ids
#PS2SNPFILE=~/octoploid_mapping/axiom_chip_info/IStraw90.r1.ps2snp_map.ps
#probe2snp.sh probesetid_map.csv ${PS2SNPFILE} snpid_map.csv

echo convert to joinmap...

#convert to joinmap compatible files
mkdir -p joinmap
cl_loc2joinmap.sh   finalgrps    joinmap/uniq.loc
cl_map2joinmap.sh   finalgrps    joinmap/uniq.map

cl_loc2joinmap.sh   finalredun   joinmap/redun.loc
cl_map2joinmap.sh   finalredun   joinmap/redun.map
