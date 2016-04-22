#!/usr/bin/python

#
# calculate mapping accuracy in a way which penalises incorrect ordering 
# and over/under splitting
# for n true lgs and m test lgs calculates an nxm matrix
# each element is the magnitude of the correlation coefficient
# between the map positions of the shared markers
# weighted by the proportion of true markers in the test group
# each element is divided by the number of nonzero elements in
# its row and column
# a perfect score is 1.0
# does not penalise linear map expansion
#

import sys
import glob
from scipy.stats import pearsonr
import numpy as np

if len(sys.argv) != 3:
    print "usage: mapping_accuracy.py <ref_map_csv> <test_map_csv>"
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

score_matrix = np.zeros((len(map1),len(map2)))

#find the weighted correlation score for all against all lgs
for i,lg1 in enumerate(map1): #for each lg in map1
    
    for j,lg2 in enumerate(map2): #for each lg in map2
        #find positions of markers common to both lgs
        xx = []
        yy = []
        for uid in lg1:
            if not uid in lg2: continue
            xx.append(float(lg1[uid][2]))
            yy.append(float(lg2[uid][2]))
            
        if len(xx) == 0:
            score_matrix[i][j] = 0.0
            continue
            
        #find magnitude of correlation coefficient
        if len(xx) == 1:
            corr = 1.0
        else:
            corr = abs(pearsonr(xx,yy)[0])
        
        #what proportion of lg1 markers are in lg2?
        prop = float(len(xx)) / nmarkers1

        score_matrix[i][j] = prop * corr
    
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
