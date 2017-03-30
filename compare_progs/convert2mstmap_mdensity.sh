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
# convert mdensity test data to mstmap format, backcross encoded
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/bin
export PATH=${PATH}:/home/vicker/git_repos/crosslink/compare_progs
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

OUTDIR=/home/vicker/crosslink/ploscompbiol_data/mdensity_simdata/sample_data

cd ${OUTDIR}

#POP_SIZE=200            #how many progeny

for dname in *_*
do
    cd ${dname}
    
    #NMARKERS=$(cat sample.loc | wc --lines)

    #convert to mstmap backcross format
    #provide the correct phase info so incorrect phasing cannot cause errors
    convert2mstmap.py sample.loc orig/000.orig sample.mstmat sample.mstpat

    cd ..
done
