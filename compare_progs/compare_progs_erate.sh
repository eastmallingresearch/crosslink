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
# note:grid_run is a simple wrapper on top of SunGridEngine's qsub
#

set -eu

export PATH=${PATH}:/home/vicker/git_repos/crosslink/compare_progs

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/erate_simdata

SCRIPTDIR=${CROSSLINK_PATH}/compare_progs

cd ${OUTDIR}

MAXJOBS=12
GIGS=3

rm -f joblist

eratelist='0.001 0.005 0.01 0.03 0.06'

for erate in ${eratelist}
do
    for SAMPLE_DIR in sample_data/${erate}_*
    do
        export SAMPLE_DIR
        echo ${SAMPLE_DIR}
        SAMPLEBASE=$(basename ${SAMPLE_DIR})

        grid_run -L${MAXJOBS} -M${GIGS} -Jmstmap_${SAMPLEBASE}    "${SCRIPTDIR}/run_mstmap.sh" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jlepmap_${SAMPLEBASE}    "${SCRIPTDIR}/run_lepmap.sh" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jtmap_${SAMPLEBASE}      "${SCRIPTDIR}/run_tmap.sh" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jom_ug_${SAMPLEBASE}     "${SCRIPTDIR}/run_onemap.sh om_ug" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jcl_approx_${SAMPLEBASE} "${SCRIPTDIR}/run_crosslink.sh cl_approx" >> joblist
        grid_run -L${MAXJOBS} -M${GIGS} -Jcl_full_${SAMPLEBASE}   "${SCRIPTDIR}/run_crosslink.sh cl_full" >> joblist
    done
done

#wait for programs to finish running
#grid_wait -Ljoblist
