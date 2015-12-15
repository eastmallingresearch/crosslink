#!/usr/bin/python

'''
compare marker orders in two maps
assumes only a single linkage group
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--map1',default=None,type=str,help='file containing list of marker names and positions')
ap.add_argument('--map2',default=None,type=str,help='file containing list of marker names and positions')
conf = ap.parse_args()

import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

mat_col = '#ff0000'
pat_col = '#00ff00'
both_col = '#0000ff'

mdict = {}

xx = []
yy = []
cc = []

noposn = -1.0

def load_map(fname,mdict,flag):
    'load data from a 2 column map file'
    f = open(fname)
    for line in f:
        tok = line.strip().split()
        if len(tok) != 2: continue
        
        name = tok[0]
        posn = float(tok[1])
        
        if name in mdict: mdict[name].append(posn)   #second position
        elif not flag:    mdict[name] = [posn]       #first position
    f.close()

#read marker data from files
load_map(conf.map1,mdict,False)
load_map(conf.map2,mdict,True)

#print mdict

#remove markers with less than two positions
mdict = {k:v for k,v in mdict.iteritems() if len(v) == 2}

for k,v in mdict.iteritems():
    xx.append(v[0])
    yy.append(v[1])
    if k.endswith('l'): cc.append(mat_col)
    if k.endswith('n'): cc.append(pat_col)
    if k.endswith('h'): cc.append(both_col)
     
mat_patch = mpatches.Patch(color=mat_col, label='mat')
pat_patch = mpatches.Patch(color=pat_col, label='pat')
both_patch = mpatches.Patch(color=both_col, label='both')
plt.legend(handles=[mat_patch,pat_patch,both_patch])

#plt.scatter(xx,yy,c='#00ff00',s=50.0)
plt.scatter(xx,yy,c=cc,s=50.0)
        
#plt.figure(1)

#histogram subplot
#ax1 = plt.subplot(111)
#ax1.boxplot([[x[0] for x in posn],[x[1] for x in posn],[x[2] for x in posn]])
#plt.legend()

plt.tight_layout()

plt.show()


