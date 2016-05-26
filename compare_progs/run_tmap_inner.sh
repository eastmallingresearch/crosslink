#!/bin/bash

#Crosslink, Copyright (C) 2016  NIAB EMR

#
# run tmap assuming there is only one linkage groups
#

export PATH=/home/vicker/programs/tmap:${PATH}

set -eu

LOD=1.0

#phase markers
phasing ${FILEBASE}.tmap sample.phased ${LOD}

#order markers
tail -n +3 ${FILEBASE}.tmap\
    | awk '{print $1}'\
    | tmap -b sample.phased\
    > sample.out
