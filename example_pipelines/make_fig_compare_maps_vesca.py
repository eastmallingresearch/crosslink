#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

'''
plot marker position according to position in two different maps
csvs must have first three columns as:
marker name,linkage group,centimorgan position
'''

# cd ~/octoploid_mapping
# ~/git_repos/crosslink/example_pipelines/make_fig_compare_maps_vesca.py \
#       --map1 ./our6plates_plus_RGxHAros/rgxha_map2/snpids.csv \
#       --map2 ./vesca/vesca2.0_snpid_posns.csv

import sys,argparse,os
import numpy as np
import matplotlib.pyplot as plt
from mapping_funcs import *

ap = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--map1',required=True,type=str,help='map1 file')
ap.add_argument('--map2',required=True,type=str,help='map2 file')
ap.add_argument('--filter1',default=None,type=str,help="""map1 marker name filter (eg 'lambda x:x.split(":")[0]') """)
ap.add_argument('--filter2',default=None,type=str,help="""map2 marker name filter (eg 'lambda x:x.split(":")[0]') """)
#ap.add_argument('--conf',help='config file to load options from')
conf = ap.parse_args()
    
unmapped = -10.0

#map1 = genmap(file1,markerfilter=lambda x:x.split(':')[0])
#map2 = genmap(file2,markerfilter=lambda x:x.split(':')[0])

map1 = genmap(conf.map1,markerfilter=eval(str(conf.filter1)))
map2 = genmap(conf.map2,markerfilter=eval(str(conf.filter2)))

xposn = []
yposn = []
col = []

for marker in map1.mkdict.iterkeys():
    if not marker in map2.mkdict: continue
    xposn.append(map1.mkdict[marker].cumposn)
    yposn.append(map2.mkdict[marker].cumposn)
    
    #get lg offsets in both maps
    xlg = map1.lgdict[map1.mkdict[marker].lg].offset
    ylg = map2.lgdict[map2.mkdict[marker].lg].offset
    
    #determine colour
    col.append(3)
    #if (xlg+ylg) % 2 == 0: col.append(1)
    #else:                  col.append(2)
    
fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(xposn,yposn,c=col,s=7,lw=0)
#ax.scatter(xposn,yposn,s=10,lw=0)
lines1 = [x.start+x.size for x in map1.lglist]
x = map1.lglist[-1]
max1 = x.start + x.size
lines2 = [x.start+x.size for x in map2.lglist]
x = map2.lglist[-1]
max2 = x.start + x.size
ax.vlines(lines1, 0.0, max2, lw=0.5)
ax.hlines(lines2, 0.0, max1, lw=0.5)

ax.set_xlim([0.0,max1])
ax.set_ylim([0.0,max2])

plt.xticks([0.0,max1],rotation='vertical',fontsize=10)
plt.yticks([0.0,max2],fontsize=10)

ax.set_xlabel("Redgauntlet x Hapil map position (cM)",fontsize=10)
#ax.set_ylabel("Holiday x Korona map position (cM)",fontsize=10)
ax.set_ylabel("$Fragaria$ $vesca$ genome position (bp)",fontsize=10)

ax.xaxis.labelpad = 10
ax.yaxis.labelpad = 20

fs=8.0

#x axis labels
xstart=max1/len(map1.lglist) * .5
xinc=max1/(len(map1.lglist) + 1)
for i,x in enumerate(map1.lglist):
    ax.text(xstart+i*xinc,-11000000.0,x.name,fontsize=fs,rotation='vertical')
    plt.plot([xstart+i*xinc+xinc/4,x.start+x.size/2.0],[-5700000,1000000],'k-',lw=1)[0].set_clip_on(False)
    
#y axis labels
xstart=max2/len(map2.lglist) * .5 - 100000
xinc=max2/(len(map2.lglist) - 0.3)
for i,x in enumerate(map2.lglist):
    ax.text(-80.0,xstart+i*xinc,x.name,fontsize=fs,ha='right')
    plt.plot([-70,10.0],[xstart+i*xinc+xinc/10,x.start+x.size/2.0],'k-',lw=1)[0].set_clip_on(False)

plt.savefig("output.png", dpi=300, bbox_inches='tight')

os.system("convert output.png rgxha2vesca.tiff")
