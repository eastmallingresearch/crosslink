#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################
#
# build a map from the Redgauntlet x Hapil sample data
# using Crosslink's helper scripts
# complete version
#
################################################################################

set -eu

#files needed to match RGxHA to an existing map of Holiday x Korona
PS2SNPFILE=~/octoploid_mapping/axiom_chip_info/IStraw90.r1.ps2snp_map.ps
REFMAPFILE=~/octoploid_mapping/hoxko/hoxko_map_snpids.csv

#copy the configuration files
cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf ./conf          

#get a working copy of the genotype data
zcat ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz > all.loc

echo grouping...

#initial exploratory grouping
cl_group.sh   all.loc   initgrps   7.0

#fix maternal/paternal marker typing errors
cl_fixtypes.sh   all.loc   all.loc   conf/fixtypes.000 

#exploratory grouping after fixing type errors
cl_group.sh   all.loc   fixgrps   7.0 

#generate list of non redundant markers
cl_findredun.sh   all.loc   all.redun   conf/findredun.000 

#impute missing values in all markers (including redundant ones)
cl_knnimpute.sh   all.loc   all.loc   conf/knnimpute.000 

#extract only the nonredundant imputed markers
cl_extract.sh   all.loc   all.redun   all.uniq 

#form linkage groups
cl_group.sh   all.uniq   uniqgrps   7.0 

#force phasing to complete down to a LOD of zero, even for falsely joined groups
cl_phase.sh   uniqgrps   phasegrps 

echo detect cross linkage group markers...

#detect cross linkage group markers
cl_detect_crosslg.sh   phasegrps   crosslg_markers   conf/detectcrosslg.000 

#filter out cross linkage group markers
cl_removemarkers.sh   all.uniq   filt.uniq   crosslg_markers

#form linkage groups
cl_group.sh   filt.uniq   filtgrps   7.0 

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

echo produce order...

#produce map order
cl_order_hkimpute.sh   filtgrps2   finalgrps   conf/orderhkimpute.000

cl_refine_order.sh   finalgrps   finalgrps   20   28   conf/refine.000 #refine map ordering using recombination count

cl_refine_order.sh   finalgrps   global  5   28   conf/refine.001 #refine map ordering using global scoring measure

#decide which version of each lg looks better 
#for x in ./finalgrps/*.loc ; do crosslink_viewer --inp=$x || break ; crosslink_viewer --inp=${x/finalgrps/global} || break ; done

exit

#which groups global version is best?
for x in 001 008 011
do
    mv finalgrps/${x}.loc finalgrps/${x}.old
    cp global/${x}.loc finalgrps/${x}.loc
done

#calc map positions
cl_mappos.sh   finalgrps   finalgrps 

#extract one map position per marker, combined if available otherwise maternal or paternal
#convert back to standard probesetid names
mkdir -p combined_map1
make_combined_map.py finalgrps/*.map | sed 's/PHR../AX/g ; s/NMH../AX/g'\
    > combined_map1/probesetids.csv

#convert probesetids into SNP ids (for better intermap comparison)
probe2snp.py ${PS2SNPFILE} combined_map1/probesetids.csv\
    > combined_map1/snpids.csv

#match up linkage groups with reference map
match_lgs.py --inp combined_map1/snpids.csv --ref ${REFMAPFILE}\
    --out combined_map1/vs_ref.csv --out2 combined_map1/mergelist

#change 2CII into 2C, make extra copy
mv combined_map1/vs_ref.csv combined_map1/tmp.csv
cat combined_map1/tmp.csv | sed 's/2CII/2C/g' > combined_map1/vs_ref.csv

#reorder wrt reference map
cl_adjustlgs.sh   finalgrps   combined_map1/vs_ref.csv   matched

cl_mappos.sh   matched   matched

mkdir -p combined_map2
make_combined_map.py matched/*.map | sed 's/PHR../AX/g ; s/NMH../AX/g'\
    > combined_map2/probesetids.csv

#convert probesetids into SNP ids (for better intermap comparison)
probe2snp.py ${PS2SNPFILE} combined_map2/probesetids.csv\
    > combined_map2/snpids.csv

#compare_maps.py --map1 ./snpids.csv --map2 ${REFMAPFILE} #compare to HOxKO

#flip orientation of 1D
mv combined_map1/vs_ref.csv combined_map1/tmp2.csv
cat combined_map1/tmp2.csv\
    | awk -v FS=',' -v OFS=',' '$2=="1D"{if($3=="False")$3="True";else$3="False"} {print}'\
    > combined_map1/vs_ref.csv
    
rm -rf matched
cl_adjustlgs.sh   finalgrps   combined_map1/vs_ref.csv   matched

cl_mappos.sh   matched   matched

rm -rf combined_map2
mkdir -p combined_map2
make_combined_map.py matched/*.map | sed 's/PHR../AX/g ; s/NMH../AX/g'\
    > combined_map2/probesetids.csv

#convert probesetids into SNP ids (for better intermap comparison)
probe2snp.py ${PS2SNPFILE} combined_map2/probesetids.csv\
    > combined_map2/snpids.csv

#compare_maps.py --map1 ./snpids.csv --map2 ${REFMAPFILE} #compare to HOxKO

#reinsert redundant markers into genotype files
cl_reinsert_loc.sh   matched   all.loc   all.redun   matchedredun   conf/reinsert.000 

#reinsert redundant markers into map files
cl_reinsert_map.sh   matched   all.redun   matchedredun

##convert to joinmap compatible files
mkdir -p joinmap
cl_loc2joinmap.sh   matched    joinmap/uniq.loc
cl_map2joinmap.sh   matched    joinmap/uniq.map

cl_loc2joinmap.sh   matchedredun   joinmap/redun.loc
cl_map2joinmap.sh   matchedredun   joinmap/redun.map
