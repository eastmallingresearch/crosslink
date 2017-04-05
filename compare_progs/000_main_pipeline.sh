#!/bin/bash

#
# pipeline to test various mapping programs on simulated diploid data
# to run you will need to set appropriate directory names in all the scripts
# specifying the path to crosslink and also to the output directory you wish to use
# this script simply documents the order the steps should be run in
# and need not be used to actually execute them
#

#create simulated data sets
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
