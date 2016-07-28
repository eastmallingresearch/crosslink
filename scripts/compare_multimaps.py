#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

'''
plot marker position according to position in one map versus positions in multiple other maps
csvs must have first three columns as:
marker name,linkage group,centimorgan position
'''

import sys
import numpy as np
import matplotlib.pyplot as plt
from mapping_funcs2 import *

refmap = sys.argv[1]
map_list = sys.argv[2:]
    
map1 = loadmap(refmap)

xposn = []
yposn = []
col = []

for i,fname in enumerate(map_list):
    map2 = loadmap(fname,order=map1.order) #order lgs according to map1

    for uid in map1.loci:
        if not uid in map2.loci: continue
        
        marker = map1.loci[uid]
        lg = map1.groups[marker.lg]
        pos = marker.pos
        if lg.size > 0.0:
            pos /= lg.size
        else:
            assert pos == 0.0
        pos += lg.order
        xposn.append(pos)

        marker = map2.loci[uid]
        lg = map2.groups[marker.lg]
        pos = marker.pos
        if lg.size > 0.0:
            pos /= lg.size
        else:
            assert pos == 0.0
        pos += lg.order
        yposn.append(pos)

        col.append(i)
        
fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(xposn,yposn,c=col,s=10,lw=0)
lines = range(len(map1.groups)+1)
ax.vlines(lines, 0.0, lines[-1])
ax.hlines(lines, 0.0, lines[-1])
ax.set_xlim([0.0,lines[-1]])
ax.set_ylim([0.0,lines[-1]])
#ax.set_xlabel(refmap)
#ax.set_ylabel(conf.map2)
fs=10.0
for i,lg in enumerate(map1.order):
    ax.text(i+0.5,-1.0,lg,fontsize=fs,rotation='vertical')
    ax.text(-1.0,i+0.5,lg,fontsize=fs)
    ax.text(i,i+0.9,lg,fontsize=fs)
plt.show()
