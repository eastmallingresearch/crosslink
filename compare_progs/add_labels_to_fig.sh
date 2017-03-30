#!/bin/bash

#
# combine two figures into one using imagemagick
#

cd ~/rjv_mnt/cluster/crosslink/ploscompbiol_data/mdensity_simdata/figs

convert facet_400_plot.png \
        -background white \
        -gravity west -splice 50x0\
        -gravity south -splice 0x70\
        -pointsize 40 \
        -gravity West -annotate 270x270+40-700 'Ordering Error'\
        -gravity West -annotate 270x270+40+70   'Map Expansion'\
        -gravity West -annotate 270x270+40+800 'Run Time (hrs)'\
        -gravity South -annotate -500+30 'Error/Missing Rate (\%)'\
        -gravity South -annotate +340+30 'Marker Number'\
        ~/Dropbox/work_stuff/manuscripts/2017-03-14_CrossLink_rerevision/oxford_bioinf_figs/400_facet.png

