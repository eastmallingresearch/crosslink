#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################

#
# example pipeline to build a map from the Redgauntlet x Hapil sample data
# using Crosslink's helper scripts
# note: this is not the fully pipeline used to build the final published map
# but is a simplified version to demonstrate the use of the helper scripts
#

#set this to point towards the crosslink directory
CROSSLINK_PATH=${CROSSLINK_PATH:-/home/crosslink_user/crosslink}

################################################################################

export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${CROSSLINK_PATH}/scripts

set -eu

MINLOD=7.0

echo copy data...

#copy the configuration files
cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf ./conf          

#get a working copy of the genotype data
zcat ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz > all.loc

echo grouping...

#initial exploratory grouping
cl_group.sh   all.loc   initgrps   ${MINLOD} 

#fix maternal/paternal marker typing errors
cl_fixtypes.sh   all.loc   all.loc   conf/fixtypes.000 

#exploratory grouping after fixing type errors
cl_group.sh   all.loc   fixgrps   ${MINLOD} 

#generate list of non redundant markers
cl_findredun.sh   all.loc   all.redun   conf/findredun.000 

#impute missing values in all markers (including redundant ones)
cl_knnimpute.sh   all.loc   all.loc   conf/knnimpute.000 

#extract only the nonredundant imputed markers
cl_extract.sh   all.loc   all.redun   all.uniq 

#form linkage groups
cl_group.sh   all.uniq   uniqgrps   ${MINLOD} 

#force phasing to complete down to a LOD of zero, even for falsely joined groups
cl_phase.sh   uniqgrps   phasegrps 

echo detect cross linkage group markers...

#detect cross linkage group markers
cl_detect_crosslg.sh   phasegrps   crosslg_markers   conf/detectcrosslg.000 

#filter out cross linkage group markers
cl_removemarkers.sh   all.uniq   filt.uniq   crosslg_markers

#form linkage groups
cl_group.sh   filt.uniq   filtgrps   ${MINLOD} 

#force phasing to complete
cl_phase.sh   filtgrps   filtgrps 

#manually specify another cross linkage group marker
echo 'PHR11-89834490' >> crosslg_markers

#filter out cross linkage group markers
cl_removemarkers.sh   filt.uniq   filt.uniq   crosslg_markers

echo regroup...

#form linkage groups
cl_group.sh   filt.uniq   filtgrps2   7.0

#force phasing to complete
cl_phase.sh   filtgrps2   filtgrps2

echo finalise order...

#produce final map order
cl_order_hkimpute.sh   filtgrps2   finalgrps   conf/orderhkimpute.000

#calc map positions
cl_mappos.sh   finalgrps   finalgrps 

echo reinsert redundant loci

#reinsert redundant markers into genotype files
cl_reinsert_loc.sh   finalgrps   all.loc   all.redun   finalredun   conf/reinsert.000 

#reinsert redundant markers into map files
cl_reinsert_map.sh   finalgrps   all.redun   finalredun
