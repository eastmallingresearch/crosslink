#!/bin/bash

#
# group markers from old affy pipeline according to the old pipeline LGs
# run from rgxha_map directory
#

export PATH=${PATH}:/home/vicker/git_repos/crosslink/scripts
export PATH=${PATH}:/home/vicker/git_repos/crosslink/pag_poster

set -eu

SCRIPTDIR=/home/vicker/git_repos/crosslink/pag_poster

#split markers into one file per LG
assign_rgxha_markers2lgs2.py ./prev_map/rgxha_renamed.map.csv\
                             ./prev_map/crosslink_nopadding.csv\
                             ./prev_map/RGxHA_grouped
                            
#add correct headers to each file
for fname in ./prev_map/RGxHA_grouped_*.loc
do
    nmarkers=$(cat ${fname} | wc --lines)
    nsamples=$(head -n 1 ${fname} | awk '{print NF-3}')

    outname=${fname/\.loc/_final.loc}

    echo 'name = RGxHA'       >  ${outname}
    echo 'popt = CP'          >> ${outname}
    echo "nloc = ${nmarkers}" >> ${outname}
    echo "nind = ${nsamples}" >> ${outname}
    cat ${fname}              >> ${outname}
    
    rm ${fname}
    mv ${outname} ${fname}
done
