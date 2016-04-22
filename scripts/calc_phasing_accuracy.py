#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# find proportion of markers placed in correct linkage groups
# AND phased correctly
#

import sys
import glob
import numpy as np

if len(sys.argv) != 3:
    print "usage: calc_phasing_accuracy.py '<reference_loc_glob>' '<test_loc_glob>'"
    exit(0)

def load_map(glb):
    markers = []
    nmarkers = 0
    nphases = 0
    for fname in glob.glob(glb):
        markers.append({})
        f = open(fname)
        for line in f:
            tok = line.strip().split()
            uid = tok[0]
            phase = tok[2][1:-1]
            
            if tok[1] == '<hkxhk>': nphases += 2
            else:                   nphases += 1
            
            markers[-1][uid] = phase
            nmarkers += 1
        f.close()

    return markers,nmarkers,nphases

#load original markers
map1,nmarkers1,nphases1 = load_map(sys.argv[1])

#load markers being tested
map2,nmarkers2,nphases2 = load_map(sys.argv[2])

#reference map must have at least as many markers as the evaluated map
assert nmarkers1 >= nmarkers2

score_matrix = np.zeros((len(map1),len(map2)))

#copmare all against all lgs
for i,lg1 in enumerate(map1): #for each lg in map1
    
    for j,lg2 in enumerate(map2): #for each lg in map2
        #find positions of markers common to both lgs
        count = 0
        for uid in lg1:
            if uid in lg2:
                count += 1
            
        #what proportion of total markers are shared between lg1 and lg2?
        prop = float(count) / nmarkers1
         
        total_phases = 0
        total_correct = 0
        for x in [0,1]:
            phases = 0
            diff = 0
            
            #how many phases do the shared markers have
            #how many are different
            for uid in lg1:
                if uid in lg2:
                   if lg1[uid][x] == '-': continue
                   phases += 1
                   if lg2[uid][x] !=  lg1[uid][x]: diff += 1
                   
            if diff > phases / 2.0:
                total_correct += diff           #treat as antiphase
                
            else:
                total_correct += phases - diff   #treat as same phase
            
            total_phases += phases
            
        if total_phases > 0: score_matrix[i][j] = prop * float(total_correct) / total_phases

#penalise eval lgs which contain markers from more than one true lg
#by dividing the score by the number of true lgs they represent
#and penalise for splitting up true lgs between more than one eval lgs
#by dividing scores by the number of fragments a true lgs is split into
col_cts = (score_matrix != 0.0).sum(0)
row_cts = (score_matrix != 0.0).sum(1)

for i,x in enumerate(col_cts):
    if x > 0:
        score_matrix[:,i] /= x
        
for i,x in enumerate(row_cts):
    if x > 0:
        score_matrix[i,:] /= x

print score_matrix.sum()
