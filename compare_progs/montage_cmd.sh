#!/bin/bash

#
# combine two figures into one using imagemagick
#

cd ~/rjv_mnt/cluster/crosslink/ploscompbiol_data
montage erate_simdata/figs/3way_erate_400.tiff \
        mdensity_simdata/figs/3way_mdensity_400.tiff \
        -tile 1x2 -geometry +0+0 \
        ~/Dropbox/work_stuff/manuscripts/2017-03-14_CrossLink_rerevision/oxford_bioinf_figs/400.png
