#!/usr/bin/python

'''
plot marker position according to position in two different maps
csvs must have first three columns as:
marker name,linkage group,centimorgan position
'''

import sys,argparse
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

for marker in map1.mkdict.iterkeys():
    if not marker in map2.mkdict: continue
    xposn.append(map1.mkdict[marker].cumposn)
    yposn.append(map2.mkdict[marker].cumposn)
    
fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(xposn,yposn,'o')
lines1 = [x.start+x.size for x in map1.lglist]
x = map1.lglist[-1]
max1 = x.start + x.size
lines2 = [x.start+x.size for x in map2.lglist]
x = map2.lglist[-1]
max2 = x.start + x.size
ax.vlines(lines1, 0.0, max2)
ax.hlines(lines2, 0.0, max1)
ax.set_xlim([0.0,max1])
ax.set_ylim([0.0,max2])
ax.set_xlabel(conf.map1)
ax.set_ylabel(conf.map2)
fs=10.0
for x in map1.lglist: ax.text(x.start+x.size/2.0,-100.0,x.name,fontsize=fs,rotation='vertical')
for x in map2.lglist: ax.text(-100.0,x.start+x.size/2.0,x.name,fontsize=fs)
plt.show()
