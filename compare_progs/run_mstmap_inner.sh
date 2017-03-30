#!/bin/bash

#Crosslink, Copyright (C) 2016  NIAB EMR

#
# run mstmap
#

set -eu

/home/vicker/programs/MSTMap/mstmap_O3 ${FILEBASE}.mstmat sample.outmat
/home/vicker/programs/MSTMap/mstmap_O3 ${FILEBASE}.mstpat sample.outpat
