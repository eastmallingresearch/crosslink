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
# convert each dataset into joinmap format
#

#run from ~/crosslink/ploscompbiol_data/erate_simdata/

export PATH=${PATH}:/home/vicker/git_repos/crosslink/bin
export PATH=${PATH}:/home/vicker/git_repos/crosslink/compare_progs
export PATH=${PATH}:/home/vicker/git_repos/rjvbio

set -eu

POP_SIZE=200            #how many progeny

for SAMPLEDIR in sample_data/*
do
    cd ${SAMPLEDIR}

    NMARKERS=$(cat sample.loc | wc --line)
    echo "name = popname"     >  jmsample.loc
    echo "popt = CP"          >> jmsample.loc
    echo "nloc = ${NMARKERS}" >> jmsample.loc
    echo "nind = ${POP_SIZE}" >> jmsample.loc
    cat sample.loc | sed 's/ {..} / /g'            >> jmsample.loc
    
    cd -
done
