#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#
# build rgxha map
# using helper scripts
#

#change this to point towards the crosslink directory
CROSSLINK_PATH=/home/vicker/git_repos/crosslink

SCRIPT_DIR=${CROSSLINK_PATH}/test_scripts
export PATH=${PATH}:${CROSSLINK_PATH}/bin
export PATH=${PATH}:${CROSSLINK_PATH}/scripts
export PATH=${PATH}:${SCRIPT_DIR}

set -eu

if [ "$(pwd)" != "/home/vicker/crosslink/ploscompbiol_data/rgxha/test1" ]
then
    echo wrong working directory
    exit
fi

mkdir -p figs
mkdir -p logs

#zcat ${CROSSLINK_PATH}/sample_data/rgxha.loc.gz > all.loc        #get new copy of raw data

#cl_group.sh   all.loc   initgrps   6.0 #initial exploratory grouping (optional)

#cl_fixtypes.sh   all.loc   all.loc   conf/fixtypes.000 #fix maternal/paternal marker typing errors

#cl_group.sh   all.loc   initgrps   6.0 #initial exploratory grouping (optional)

#cl_findredun.sh   all.loc   all.redun   conf/findredun.000 #generate list of non redundant markers

#cl_knnimpute.sh   all.loc   all.loc   conf/knnimpute.000 #impute missing values in the markers

#cl_extract.sh   all.loc   all.redun   all.uniq #extract the imputed values for the nonredundant markers only

#cl_group.sh   all.uniq   uniqgrps   6.0 #form linkage groups for real

#cl_phase.sh   uniqgrps   uniqgrps #force phasing to complete

MAXJOBS=200

for TRIAL in $(seq 1 200)
do
    for CL_HOMEO_MINCOUNT in 2 3 4 5 6 7 10 15 20 25
    do
        for CL_HOMEO_MINLOD in 0.25 0.5 0.75 1 1.5 2 2.5
        do
            for CL_HOMEO_MAXLOD in 5 7.5 10 12.5 15 20 25
            do
                
                while true
                do
                    NJOBS=$(qstat | grep vicker | wc --lines)
                    echo ${NJOBS}
                    
                    if [ "${NJOBS}" -lt "${MAXJOBS}" ]
                    then
                        break
                    fi
                    
                    sleep 1
                done

                #launch the job
                OUTDIR=${TRIAL}_${CL_HOMEO_MINCOUNT}_${CL_HOMEO_MINLOD}_${CL_HOMEO_MAXLOD}
                export OUTDIR CL_HOMEO_MINCOUNT CL_HOMEO_MINLOD CL_HOMEO_MAXLOD

                myqsub.sh ${CROSSLINK_PATH}/test_scripts/test_rgxha_1.sh
            done
        done
    done
done

cl_detect_crosslg.sh   uniqgrps   crosslg_markers   conf/detectcrosslg.000 #detect cross lg markers

echo crosslg detection accuracy $(calc_crosslg_accuracy.py crossmarkers_list 'init/*.log')

#for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

#echo 'PHR11-89827534' >  conf/badmarkers #004 bad marker
#cl_removemarkers.sh   uniqgrps/004.loc   uniqgrps/004.loc   conf/badmarkers
#cl_subgroup.sh   uniqgrps/004.loc   6.0   uniqgrps   conf/subgroup.000

#echo 'PHR11-89779712' >> conf/badmarkers #006 bad marker
#echo 'PHR11-89819206' >> conf/badmarkers #006 bad marker
#cl_removemarkers.sh   uniqgrps/006.loc   uniqgrps/006.loc   conf/badmarkers
#cl_subgroup.sh   uniqgrps/006.loc   6.0   uniqgrps   conf/subgroup.000

#echo 'PHR11-89838939' >> conf/badmarkers #011 bad marker
#cl_removemarkers.sh   uniqgrps/011.loc   uniqgrps/011.loc   conf/badmarkers
#cl_subgroup.sh   uniqgrps/011.loc   6.0   uniqgrps   conf/subgroup.000

#echo 'PHR11-89878711' >> conf/badmarkers #015 bad marker
#cl_removemarkers.sh   uniqgrps/015.loc   uniqgrps/015.loc   conf/badmarkers
#cl_subgroup.sh   uniqgrps/015.loc   6.0   uniqgrps   conf/subgroup.000

#echo 'PHR11-89834490' >> conf/badmarkers #017 bad marker
#cl_removemarkers.sh   uniqgrps/017.loc   uniqgrps/017.loc   conf/badmarkers
#cl_subgroup.sh   uniqgrps/017.loc   6.0   uniqgrps   conf/subgroup.000

#for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

#cl_subgroup.sh   uniqgrps/006.002.loc   6.5   uniqgrps   conf/subgroup.000  #006.002 split at higher lod
#cl_subgroup.sh   uniqgrps/011.001.loc   7.0   uniqgrps   conf/subgroup.000  #011.001 split at higher lod

#cl_mappos.sh   uniqgrps   uniqgrps #calc map positions
#cl_reinsert_loc.sh   uniqgrps   all.loc   all.redun   redun   conf/reinsert.000 #reinsert redundant markers
#cl_reinsert_map.sh   uniqgrps   all.redun   redun
#cl_match2ref.sh   redun   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map

#cat vs_ref.csv | sed 's/2CII/2C/g' > tmp.csv #convert 2CII into 2C
#rm vs_ref.csv
#mv tmp.csv vs_ref.csv

###would do synteny based merging here, but none is required for rgxha

#for x in uniqgrps/*.loc ; do crosslink_viewer --inp=${x} || break ; done #view lgs

#cl_refine_order.sh   uniqgrps   uniqrefined   10   28   conf/refine.* #refine map ordering using trial and error

#cl_refine_order.sh   uniqgrps   uniqglobal   5   28   conf/refine2.global #refine map ordering using global scoring measure

#for x in ./uniqrefined/*.loc ; do crosslink_viewer --inp=${x} || break ; crosslink_viewer --inp=./uniqglobal/$(basename ${x}) || break ; done

#mkdir -p uniqbest #select the best orderings
#cp uniqrefined/*.loc uniqbest
#cp uniqglobal/003.loc uniqglobal/009.loc uniqglobal/017.000.loc uniqbest

#cl_mappos.sh   uniqbest   uniqbest #create map distances

#rm redun/* #update redundant version of the map
#cl_reinsert_loc.sh   uniqbest   all.loc   all.redun   redun   conf/reinsert.000
#cl_reinsert_map.sh   uniqbest   all.redun   redun

#cl_match2ref.sh   redun   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map again
#cat vs_ref.csv | sed 's/2CII/2C/g' > tmp.csv #convert 2CII into 2C
#rm vs_ref.csv && mv tmp.csv vs_ref.csv
#nano vs_ref.csv   ###flip orientation of 1D

#cl_adjustlgs.sh   uniqbest   vs_ref.csv   uniqfinal #reorder uniq loci wrt reference map

#cl_mappos.sh   uniqfinal   uniqfinal #final map positions

#cl_reinsert_loc.sh   uniqfinal   all.loc   all.redun   redunfinal   conf/reinsert.000 #create final redundant version
#cl_reinsert_map.sh   uniqfinal   all.redun   redunfinal

#cl_match2ref.sh   redunfinal   ${REFMAPFILE}   ${PS2SNPFILE} #match up LGs to the reference map once again

#compare_maps.py --map1 ./snpids.csv --map2 ../../vesca/vesca2.0_snpid_posns.csv #compare to vesca
#compare_maps.py --map1 ./snpids.csv --map2 ../../hoxko/hoxko_map_snpids.csv #compare to HOxKO

##convert to joinmap compatible files
#mkdir -p joinmap
#cl_loc2joinmap.sh   uniqfinal    joinmap/uniq.loc
#cl_map2joinmap.sh   uniqfinal    joinmap/uniq.map

#cl_loc2joinmap.sh   redunfinal   joinmap/redun.loc
#cl_map2joinmap.sh   redunfinal   joinmap/redun.map

#####remove bad markers and perform forced type switching
####cl_modifymarkers.sh   all.loc   all.loc   conf/modifymarkers.000
