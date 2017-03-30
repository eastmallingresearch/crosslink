#!/bin/bash

#
# combine two figures into one using imagemagick
#

cd ~/rjv_mnt/cluster/crosslink/ploscompbiol_data
montage erate_simdata/figs/erate_ordering_400.png \
        mdensity_simdata/figs/mden_ordering_400.png \
        erate_simdata/figs/erate_time_400.png \
        mdensity_simdata/figs/mden_time_400.png \
        erate_simdata/figs/erate_expansion_400.png\
        mdensity_simdata/figs/mden_expansion_400.png\
        -tile 2x3 -geometry +0+0 \
        ~/Dropbox/work_stuff/manuscripts/2017-03-14_CrossLink_rerevision/oxford_bioinf_figs/400.png

cp mdensity_simdata/figs/mden_legend_400.png ~/Dropbox/work_stuff/manuscripts/2017-03-14_CrossLink_rerevision/oxford_bioinf_figs
