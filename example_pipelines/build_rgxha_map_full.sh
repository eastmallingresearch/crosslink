#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################
#
# full version of Redgauntlet x Hapil mapping pipeline
#
# IMPORTANT: this file acts to document the steps taken to produce the final map
# and is not intended to be simply run as a script from start to finish
# if you require to replicate all the step here it is recommended to 
# run the steps one at a time by copy-pasting into the terminal or similar
# 
# some steps also require access to the IStraw90.r1.ps2snp_map.ps file from
# the Affymetrix Axiom(R) IStraw90 array and to the Holiday x Korona SNP map
# (which is not yet publically available as of time of writing) in order to
# rename the linkage groups
#
################################################################################

export CROSSLINK_PATH=/home/vicker/git_repos/crosslink
export PATH=${PATH}:${CROSSLINK_PATH}/scripts:${CROSSLINK_PATH}/bin

set -eu

PS2SNPFILE=../../axiom_chip_info/IStraw90.r1.ps2snp_map.ps  #which probeset(s) query which snp
REFMAPFILE=../../hoxko/hoxko_map_snpids.csv                 #draft Holiday x Korona SNP map

cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf_full ./conf  #copy the configuration files

zcat ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz > all.loc #get new copy of raw data

cl_group.sh   all.loc   initgrps   6.0 #initial exploratory grouping (optional)

cl_fixtypes.sh   all.loc   all.loc   conf/fixtypes.000 #fix maternal/paternal marker typing errors

cl_group.sh   all.loc   initgrps   6.0 #initial exploratory grouping (optional)

cl_findredun.sh   all.loc   all.redun   conf/findredun.000 #generate list of non redundant markers

cl_knnimpute.sh   all.loc   all.loc   conf/knnimpute.000 #impute missing values in the markers

cl_extract.sh   all.loc   all.redun   all.uniq #extract the imputed values for the nonredundant markers only

cl_group.sh   all.uniq   uniqgrps   6.0 #form linkage groups for real

cl_phase.sh   uniqgrps   uniqgrps #phase markers

cl_order_hkimpute.sh   uniqgrps   uniqgrps   conf/orderhkimpute.000 #order markers

for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

echo 'PHR11-89827534' >  conf/badmarkers #004 bad marker
cl_removemarkers.sh   uniqgrps/004.loc   uniqgrps/004.loc   conf/badmarkers
cl_subgroup.sh   uniqgrps/004.loc   6.0   uniqgrps   conf/subgroup.000

echo 'PHR11-89779712' >> conf/badmarkers #006 bad marker
echo 'PHR11-89819206' >> conf/badmarkers #006 bad marker
cl_removemarkers.sh   uniqgrps/006.loc   uniqgrps/006.loc   conf/badmarkers
cl_subgroup.sh   uniqgrps/006.loc   6.0   uniqgrps   conf/subgroup.000

echo 'PHR11-89838939' >> conf/badmarkers #011 bad marker
cl_removemarkers.sh   uniqgrps/011.loc   uniqgrps/011.loc   conf/badmarkers
cl_subgroup.sh   uniqgrps/011.loc   6.0   uniqgrps   conf/subgroup.000

echo 'PHR11-89878711' >> conf/badmarkers #015 bad marker
cl_removemarkers.sh   uniqgrps/015.loc   uniqgrps/015.loc   conf/badmarkers
cl_subgroup.sh   uniqgrps/015.loc   6.0   uniqgrps   conf/subgroup.000

echo 'PHR11-89834490' >> conf/badmarkers #017 bad marker
cl_removemarkers.sh   uniqgrps/017.loc   uniqgrps/017.loc   conf/badmarkers
cl_subgroup.sh   uniqgrps/017.loc   6.0   uniqgrps   conf/subgroup.000

for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

cl_subgroup.sh   uniqgrps/006.002.loc   6.5   uniqgrps   conf/subgroup.000  #006.002 split at higher lod
cl_subgroup.sh   uniqgrps/011.001.loc   7.0   uniqgrps   conf/subgroup.000  #011.001 split at higher lod

cl_mappos.sh   uniqgrps   uniqgrps #calc map positions
cl_reinsert_loc.sh   uniqgrps   all.loc   all.redun   redun   conf/reinsert.000 #reinsert redundant markers
cl_reinsert_map.sh   uniqgrps   all.redun   redun
cl_match2ref.sh   redun   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map

cat vs_ref.csv | sed 's/2CII/2C/g' > tmp.csv #convert 2CII into 2C
rm vs_ref.csv
mv tmp.csv vs_ref.csv

for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

cl_refine_order.sh   uniqgrps   uniqrefined   10   28   conf/refine.* #refine map ordering using trial and error

cl_refine_order.sh   uniqgrps   uniqglobal   5   28   conf/refine2.global #refine map ordering using global scoring measure

for x in ./uniqrefined/*.loc ; do crosslink_viewer --inp=${x} || break ; crosslink_viewer --inp=./uniqglobal/$(basename ${x}) || break ; done #compare global with recomb count orderings

mkdir -p uniqbest #select the best orderings
cp uniqrefined/*.loc uniqbest
cp uniqglobal/003.loc uniqglobal/009.loc uniqglobal/017.000.loc uniqbest

cl_mappos.sh   uniqbest   uniqbest #create map distances

rm redun/* #update redundant version of the map
cl_reinsert_loc.sh   uniqbest   all.loc   all.redun   redun   conf/reinsert.000
cl_reinsert_map.sh   uniqbest   all.redun   redun

cl_match2ref.sh   redun   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map again
cat vs_ref.csv | sed 's/2CII/2C/g' > tmp.csv #convert 2CII into 2C
rm vs_ref.csv && mv tmp.csv vs_ref.csv
nano vs_ref.csv   ###flip orientation of 1D

cl_adjustlgs.sh   uniqbest   vs_ref.csv   uniqfinal #reorder uniq loci wrt reference map

cl_mappos.sh   uniqfinal   uniqfinal #final map positions

cl_reinsert_loc.sh   uniqfinal   all.loc   all.redun   redunfinal   conf/reinsert.000 #create final redundant version
cl_reinsert_map.sh   uniqfinal   all.redun   redunfinal

cl_match2ref.sh   redunfinal   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map once again

compare_maps.py --map1 ./snpids.csv --map2 ${REFMAPFILE} #compare to reference map

#convert to joinmap compatible files
mkdir -p joinmap
cl_loc2joinmap.sh   uniqfinal    joinmap/uniq.loc
cl_map2joinmap.sh   uniqfinal    joinmap/uniq.map

cl_loc2joinmap.sh   redunfinal   joinmap/redun.loc
cl_map2joinmap.sh   redunfinal   joinmap/redun.map
