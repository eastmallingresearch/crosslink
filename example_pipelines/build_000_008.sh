#!/bin/bash
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

################################################################################

#
# process just two example genotype files from the Redgauntlet x Hapil dataset
# for use with the getting started section introducing the data visualisation tools
#

#set this to point towards the crosslink directory
CROSSLINK_PATH=${CROSSLINK_PATH:-/home/vicker/rjv_mnt/cluster/git_repos/crosslink}

################################################################################

export PATH=${CROSSLINK_PATH}/bin:${CROSSLINK_PATH}/scripts:${PATH}

set -eu

#copy the configuration files
cp -r ${CROSSLINK_PATH}/sample_data/rgxha_conf ./conf

#this file grouped correctly already
zcat ${CROSSLINK_PATH}/sample_data/000.loc.gz > 000.loc
cl_fixtypes.sh   000.loc   000.fix   conf/fixtypes.000 
cl_findredun.sh   000.fix   000.redun   conf/findredun.000 
cl_knnimpute.sh   000.fix   000.imp   conf/knnimpute.000 
cl_extract.sh   000.imp   000.redun   000.uniq 
mkdir -p 000.dir
cp 000.uniq 000.dir/000.loc
cl_order_hkimpute.sh   000.dir   000.final   conf/orderhkimpute.000
cl_mappos.sh   000.final   000.final
cl_reinsert_loc.sh   000.final   000.imp   000.redun   000.finalredun   conf/reinsert.000 
cl_reinsert_map.sh   000.final   000.redun   000.finalredun


