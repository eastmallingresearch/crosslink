#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# find proportion of missing data that was correctly imputed
#

import sys
import glob

if len(sys.argv) != 4:
    print "usage: calc_imputing_accuracy.py '<original_glob>' '<missing_glob>' '<imputed_glob>'"
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
missing = {}
for fname in glob.glob(sys.argv[2]):
    f = open(fname)
    for line in f:
        tok = line.strip().split()
        missing[tok[0]] = tok
    f.close()
    
#load data with missing values
imputed = {}
for fname in glob.glob(sys.argv[3]):
    f = open(fname)
    for line in f:
        tok = line.strip().split()
        imputed[tok[0]] = tok
    f.close()
    
total_missing = 0
total_correct = 0
for uid in orig:
    if not uid in missing: continue
    
    for i,x in enumerate(missing[uid]):
        if i < 3: continue
        
        if missing[uid][i] != '--': continue
        total_missing += 1
        
        if not uid in imputed: continue
        
        if orig[uid][i] in ['hk','kh']:
            if imputed[uid][i] in ['hk','kh']:
                total_correct += 1
        elif imputed[uid][i] == orig[uid][i]:
            total_correct += 1
    
if total_missing > 0.0:
    print "%.10lf"%(float(total_correct)/total_missing)
else:
    print "1.0"
