#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################
#
# process just one example linkage group from the Redgauntlet x Hapil dataset
# for use with the getting started section introducing the data visualisation tools
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
if [ ! -f ${CROSSLINK_PATH}/sample_data/000.loc.gz ]
then
    echo "Could not find the sample data at ${CROSSLINK_PATH}/sample_data/000.loc.gz"
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

#copy the configuration files
cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf ./conf

#extract working copy of the single linkage group
zcat ${CROSSLINK_PATH}/sample_data/000.loc.gz > 000.loc

#fix marker typing errors
cl_fixtypes.sh   000.loc   000.fix   conf/fixtypes.000 

#find redundant markers
cl_findredun.sh   000.fix   000.redun   conf/findredun.000 

#impute missing values
cl_knnimpute.sh   000.fix   000.imp   conf/knnimpute.000 

#extract imputed version of non-redundant markers
cl_extract.sh   000.imp   000.redun   000.uniq 

#make final ordering and impute hk information 
mkdir -p 000.dir
cp 000.uniq 000.dir/000.loc
cl_order_hkimpute.sh   000.dir   000.final   conf/orderhkimpute.000

#find final map positions
cl_mappos.sh   000.final   000.final

#reinsert redundant markers
cl_reinsert_loc.sh   000.final   000.imp   000.redun   000.finalredun   conf/reinsert.000 
cl_reinsert_map.sh   000.final   000.redun   000.finalredun
