#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
'''
plot estimated versus correct map positions
colour coded to show marker type: maternal-only/paternal-only/both
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--inp',default=None,type=str,help='file containing list of marker names and positions in maternal/paternal/combined maps')
ap.add_argument('--maptype',default='map',type=str,help='map, loc or tmp')
ap.add_argument('--NA',default='NA',type=str,help='string used to denote missing values')
conf = ap.parse_args()

import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

mat_col = '#ff0000'
pat_col = '#00ff00'
both_col = '#0000ff'

xx = []
yy = []
cc = []

def load_map(f,xx,yy,cc):
    'load data from 4 column map file'
    f.readline() #skip header

    for line in f:
        tok = line.strip().split()
        assert len(tok) == 4
        
        name = tok[0]
        x = float(name.split('_')[1][:-1]) #extract true position from marker name
        y = float(tok[3])             #estimated position from combined map
        
        #deduce marker type from mat/pat map info tokens
        if tok[1] == conf.NA:   c = pat_col
        elif tok[2] == conf.NA: c = mat_col
        else:                   c = both_col
        
        xx.append(x)
        yy.append(y)
        cc.append(c)

def load_map2(f,xx,yy,cc):
    'load data from 2 column map file'

    for line in f:
        tok = line.strip().split()
        
        if len(tok) < 2: continue
        if not tok[0].startswith("m"): continue
        assert len(tok) == 2
        
        name = tok[0]
        x = float(name.split('_')[1][:-1]) #extract true position from marker name
        y = float(tok[1])             #estimated position from combined map
        
        mtype = name.split('_')[1][-1]
        
        #unknown colour type
        if mtype == 'l':   c = mat_col
        elif mtype == 'n': c = pat_col
        else:              c = both_col
        
        xx.append(x)
        yy.append(y)
        cc.append(c)

def load_tmp(f,xx,yy,cc):
    'load data from temporary file type used during testing'

    for line in f:
        tok = line.strip().split()
        assert len(tok) == 3
        
        name = tok[0]
        x = float(name.split('_')[1]) #extract true position from marker name
        mtype = tok[1]                #0=mat 1=pat
        y = float(tok[2])             #estimate position
        
        #deduce marker type from mat/pat map info tokens
        if   mtype == '<lmxll>' or mtype == '0': c = mat_col
        elif mtype == '<nnxnp>' or mtype == '1': c = pat_col
        else:                                    c = both_col
        
        xx.append(x)
        yy.append(y)
        cc.append(c)

def load_loc(f,xx,yy,cc):
    'load data from loc file'
    
    for i in xrange(5): f.readline() #skip header

    for i,line in enumerate(f):
        tok = line.strip().split()[:2]
        assert len(tok) == 2
        
        name = tok[0]
        x = float(name.split('_')[1][:-1]) #extract true position from marker name
        y = float(i)             #estimated map order
        
        #deduce marker type from second token
        if tok[1] == '<lmxll>':   c = mat_col
        elif tok[1] == '<nnxnp>': c = pat_col
        else:                     c = both_col
        
        xx.append(x)
        yy.append(y)
        cc.append(c)

#prepare to read from the posteriors file
f = open(conf.inp)

if conf.maptype == 'loc':
    load_loc(f,xx,yy,cc)
elif conf.maptype == 'tmp':
    load_tmp(f,xx,yy,cc)
elif conf.maptype == 'map2':
    load_map2(f,xx,yy,cc)
else:
    load_map(f,xx,yy,cc)

f.close()

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


