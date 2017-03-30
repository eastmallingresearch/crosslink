#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# mapping accuracy: ordering correlation, map expansion, percentage missing markers
#

import sys
import glob
import math
from scipy.stats import pearsonr
import numpy as np

if len(sys.argv) != 3:
    print "usage: mapping_accuracy_1lg.py <ref_map_csv> <test_map_csv>"
    exit(0)

def load_map(glb):
    prev = 9999999
    maplist = []
    nmarkers = 0
    for fname in glob.glob(glb):
        f = open(fname)
        for line in f:
            tok = line.strip().split(',')
            uid = tok[0]
            lg = tok[1]
            if lg != prev: maplist.append({})
            prev = lg
            maplist[-1][uid] = tok
            nmarkers += 1
        f.close()

    return maplist,nmarkers

#load reference map
map1,nmarkers1 = load_map(sys.argv[1])

#load map to be evaluated
map2,nmarkers2 = load_map(sys.argv[2])
    
#reference map must have at least as many markers as the evaluated map
assert nmarkers1 >= nmarkers2

#find longest LG in both maps
lglist = [[lg,len(lg)] for lg in map1]
lglist.sort(key=lambda x:x[1],reverse=True)

lg1 = lglist[0][0]

lglist = [[lg,len(lg)] for lg in map2]
lglist.sort(key=lambda x:x[1],reverse=True)
lg2 = lglist[0][0]

#find positions of markers common to both lgs
xx = []
yy = []
for uid in lg1:
    if not uid in lg2: continue
    xx.append(float(lg1[uid][2]))
    yy.append(float(lg2[uid][2]))

#find magnitude of correlation coefficient
if len(xx) == 0:
    corr = 0.0
elif len(xx) == 1:
    corr = 1.0
else:
    corr = abs(pearsonr(xx,yy)[0])
    if math.isnan(corr): corr = 0.0

#proportion of lg1 markers missing from lg2
prop = float(nmarkers1 - nmarkers2) / nmarkers1

#map expansion
xx = [float(lg1[uid][2]) for uid in lg1]
xx.sort()
yy = [float(lg2[uid][2]) for uid in lg2]
yy.sort()

ratio = yy[-1] / xx[-1]

print corr,prop,ratio
