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

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/compare_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

#NSAMPLES=10
MAXJOBS=200

for SAMPLENO in $(seq 21 40)
do
    #wait for space in the queue
    while true
    do
        NJOBS=$(qstat | wc --lines)
        echo ${NJOBS}
        
        if [ "${NJOBS}" -lt "${MAXJOBS}" ]
        then
            break
        fi
        
        sleep 1
    done
    
    SAMPLE_DIR=$(printf "%03d" ${SAMPLENO})
    export SAMPLE_DIR
    myqsub.sh ${SCRIPTDIR}/run_lepmap.sh 
    myqsub.sh ${SCRIPTDIR}/run_tmap.sh 
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_record 
    #myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_seriation
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_rcd
    myqsub.sh ${SCRIPTDIR}/run_onemap.sh om_ug
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_approx 
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_full
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_refine
    myqsub.sh ${SCRIPTDIR}/run_crosslink.sh cl_global
done
