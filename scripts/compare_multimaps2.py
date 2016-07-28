#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

'''
plot marker position in multiple maps versus average position across all maps
assumes markers always map to same lg in everymap
csvs must have first three columns as:
marker name,linkage group,centimorgan position
'''

import sys
import numpy as np
import matplotlib.pyplot as plt
from mapping_funcs2 import *

order = []
for x in xrange(1,8):
    for y in 'ABCD':
        order.append(str(x)+y)

map_list = sys.argv[1:]
    
maps = [loadmap(x,order=order) for x in map_list]

pos = {}

for mp in maps:
    for uid in mp.loci:
        if not uid in pos: pos[uid] = []
        pos[uid].append(mp.loci[uid].relpos)

mean = {}
for uid in pos:
    mean[uid] = sum(pos[uid]) / len(pos[uid])

xposn = []
yposn = []
col = []

for i,mp in enumerate(maps):
    for uid in mp.loci:
        marker = mp.loci[uid]
        lg = mp.groups[marker.lg]
        xposn.append(mean[uid] + lg.order)
        yposn.append(marker.relpos + lg.order)
        col.append(i)
        
fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(xposn,yposn,c=col,s=10,lw=0)
lines = range(len(order)+1)
ax.vlines(lines, 0.0, lines[-1])
ax.hlines(lines, 0.0, lines[-1])
ax.set_xlim([0.0,lines[-1]])
ax.set_ylim([0.0,lines[-1]])
#ax.set_xlabel(refmap)
#ax.set_ylabel(conf.map2)
fs=10.0
for i,lg in enumerate(order):
    ax.text(i+0.5,-1.0,lg,fontsize=fs,rotation='vertical')
    ax.text(-1.0,i+0.5,lg,fontsize=fs)
    ax.text(i,i+0.9,lg,fontsize=fs)
plt.show()
