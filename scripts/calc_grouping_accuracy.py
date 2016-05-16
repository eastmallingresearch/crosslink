#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# calculate grouping accuracy in a way which penalises over/under splitting
# for n true lgs and m test lgs calculates an nxm matrix
# each element is the proportion of the total true markers in the test group
# each element is divided by the number of nonzero elements in
# its row and column
# a perfect score is 1.0
#

import sys
import glob
from scipy.stats import pearsonr
import numpy as np

if len(sys.argv) != 3:
    print "usage: calc_grouping_accuracy.py '<ref_loc_glob>' '<test_loc_glob>'"
    exit(0)

def load_map(glb):
    markers = []
    nmarkers = 0
    for fname in glob.glob(glb):
        markers.append({})
        f = open(fname)
        for line in f:
            uid = line.strip().split()[0]
            markers[-1][uid] = True
            nmarkers += 1
        f.close()

    return markers,nmarkers

#load reference map
map1,nmarkers1 = load_map(sys.argv[1])

#load map to be evaluated
map2,nmarkers2 = load_map(sys.argv[2])
    
#reference map must have at least as many markers as the evaluated map
assert nmarkers1 >= nmarkers2

score_matrix = np.zeros((len(map1),len(map2)))

#find the weighted correlation score for all against all lgs
for i,lg1 in enumerate(map1): #for each lg in map1
    
    for j,lg2 in enumerate(map2): #for each lg in map2
        #find positions of markers common to both lgs
        count = 0
        for uid in lg1:
            if uid in lg2:
                count += 1
            
        #what proportion of lg1 markers are in lg2?
        score_matrix[i][j] = float(count) / nmarkers1
    
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
