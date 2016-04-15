#!/usr/bin/python

#
# find proportion of hk genotypes that were correctly imputed
#

import sys
import glob

if len(sys.argv) != 3:
    print "usage: calc_hk_accuracy.py '<original_glob>' '<imputed_glob>'"
    exit(0)

#load original data
orig = {}
total_markers = 0
for fname in glob.glob(sys.argv[1]):
    f = open(fname)
    for line in f:
        tok = line.strip().split()
        orig[tok[0]] = tok
        total_markers += 1
    f.close()
    
#load data with missing values
imputed = {}
for fname in glob.glob(sys.argv[2]):
    f = open(fname)
    for line in f:
        tok = line.strip().split()
        imputed[tok[0]] = tok
    f.close()
    
total_hk = 0
total_correct = 0
for uid in orig:
    for i,x in enumerate(orig[uid]):
        if i < 3: continue
        
        if orig[uid][i] not in ['hk','kh']: continue
        total_hk += 1
        
        if not uid in imputed: continue
        
        if imputed[uid][i] == orig[uid][i]:
            total_correct += 1
    
print "%.10lf"%(float(total_correct)/total_hk)
