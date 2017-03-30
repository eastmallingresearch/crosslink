#!/bin/bash

#Crosslink
#Copyright (C) 2016  NIAB EMR
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along
#with this program; if not, write to the Free Software Foundation, Inc.,
#51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#contact:
#robert.vickerstaff@emr.ac.uk
#Robert Vickerstaff
#NIAB EMR
#New Road
#East Malling
#WEST MALLING
#ME19 6BJ
#United Kingdom

#
# test crosslink on simulated data
#

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/mdensity_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

#NSAMPLES=10
MAXJOBS=100
GIGS=20          #16

rm -f joblist

#denlist='1 5 10 50 100 150 200'
#denlist='1000'  # 5000 10000'
denlist=dummy

for den in ${denlist}
do
    #for SAMPLE_DIR in sample_data/${den}_*
    for SAMPLE_DIR in sample_data/10_1377722524 sample_data/100_2246113046 sample_data/100_294105093 sample_data/100_3185616168 sample_data/100_527011528
    do
        export SAMPLE_DIR
        echo ${SAMPLE_DIR}
        SAMPLEBASE=$(basename ${SAMPLE_DIR})
        
        #grid_run -L${MAXJOBS} -M${GIGS} -Jmstmap_${SAMPLEBASE}    "${SCRIPTDIR}/run_mstmap.sh" >> joblist
        #grid_run -L${MAXJOBS} -M${GIGS} -Jlepmap_${SAMPLEBASE}    "${SCRIPTDIR}/run_lepmap.sh" >> joblist
        #grid_run -L${MAXJOBS} -M${GIGS} -Jtmap_${SAMPLEBASE}      "${SCRIPTDIR}/run_tmap.sh" >> joblist
        #myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_record 
        ##myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_seriation
        #myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_rcd
        #grid_run -L${MAXJOBS} -M${GIGS} -Jom_ug_${SAMPLEBASE}     "${SCRIPTDIR}/run_onemap.sh om_ug" >> joblist
        #grid_run -L${MAXJOBS} -M${GIGS} -Jcl_approx_${SAMPLEBASE} "${SCRIPTDIR}/run_crosslink.sh cl_approx" >> joblist
        #grid_run -L${MAXJOBS} -M${GIGS} -Jcl_full_${SAMPLEBASE}   "${SCRIPTDIR}/run_crosslink.sh cl_full" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jcl_refine_${SAMPLEBASE}   "${SCRIPTDIR}/run_crosslink.sh cl_refine" >> joblist
        #grid_run -L${MAXJOBS} -M${GIGS} -Jcl_global_${SAMPLEBASE}   "${SCRIPTDIR}/run_crosslink.sh cl_global"
        #grid_run -L${MAXJOBS} -M${GIGS} -Jcl_redun_${SAMPLEBASE}   "${SCRIPTDIR}/run_crosslink.sh cl_redun" >> joblist
    done
done
#grid_wait -Ljoblist
