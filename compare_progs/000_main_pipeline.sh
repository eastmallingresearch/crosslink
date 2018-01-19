#!/bin/bash

#Crosslink
#Copyright (C) 2017  NIAB EMR
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
#------------------------------------------------------------------------

#
# pipeline to test various mapping programs on simulated diploid data
# to run you will need to set appropriate directory names in all the scripts
# specifying the path to crosslink and also to the output directory you wish to use
# this script simply documents the order the steps should be run in
# and need not be used to actually execute them
# to rerun this pipeline requires crosslink subfolders bin and compare_progs to
# be in the PATH
#

#create simulated data sets
#alternatively use the data in simulated_data_erate.tar.gz
#and simulated_data_mdensity.tar.gz in the release tab of the github page
#see release v0.5
create_test_data_erate.sh
create_test_data_mdensity.sh

#run scriptable programs
compare_progs_erate.sh
compare_progs_mdensity.sh

#wait for jobs to complete

#put manually run joinmap results into appropriate files (see scripts below)

#adjust mapping accuracy results
recalc_mapping_accuracy_erate.sh
recalc_mapping_accuracy_mdensity.sh

#plot figures
make_figs_both_3way_bioinf_facetgrid.R
