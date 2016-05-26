#!/bin/bash

#Crosslink, Copyright (C) 2016  NIAB EMR

#
# run onemap assuming there is only one linkage groups
#

set -eu

run_onemap_inner.R ${FILEBASE}.onemap sample.out $1

