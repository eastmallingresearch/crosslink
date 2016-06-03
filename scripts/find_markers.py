#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# find markers which are on different LGs between two maps
# usage: find_markers.py map1.csv map2.csv

import sys

fname1 = sys.argv[1]
fname2 = sys.argv[2]

mdict = {}

f = open(fname1)
for line in f:
    tok = line.strip().split(',')
    name = tok[0]
    lg = tok[1]
    pos = float(tok[2])
    
    assert name not in mdict
    mdict[name] = [[lg,pos],None]
f.close()

f = open(fname2)
for line in f:
    tok = line.strip().split(',')
    name = tok[0]
    lg = tok[1]
    pos = float(tok[2])
    
    if name not in mdict:
        mdict[name] = [None,[lg,pos]]
    else:
        mdict[name][1] = [lg,pos]
f.close()

for name in mdict:
    item = mdict[name]
    if None in item: continue
    if item[0][0][:2] != item[1][0][:2]:
        #print item
        print name, item[0][0], item[1][0] 
        
