#!/usr/bin/python

#
# measure how many markers were placed in correct linkage groups
#

import sys
import glob

if len(sys.argv) != 3:
    print "usage: calc_grouping_accuracy.py '<original_glob>' '<test_glob>'"
    exit(0)

#load correctly grouped markers, lgs separated by
orig = []
total_markers = 0
for fname in glob.glob(sys.argv[1]):
    f = open(fname)
    orig.append({})
    for line in f:
        uid = line.strip().split()[0]
        orig[-1][uid] = True
        total_markers += 1
    f.close()
    
#load markers being tested
test = []
for fname in glob.glob(sys.argv[2]):
    f = open(fname)
    test.append({})
    for line in f:
        uid = line.strip().split()[0]
        test[-1][uid] = True
    f.close()
    
orig.sort(key=lambda x:len(x),reverse=True)
test.sort(key=lambda x:len(x),reverse=True)

#for each original lg, by decreasing size
#find the test lg with most markers from it, assign this as "correct" and then remove it
#count total markers in the "correct" lg
total = 0
for lg in orig:
    best_ct = -1
    best_i = -1
    for i,x in enumerate(test):
        ct = 0
        for uid in x.iterkeys():
            if uid in lg:
                ct += 1
        if ct > best_ct:
            best_ct = ct
            best_i = i
            
    total += best_ct
    del test[best_i]
    
    if len(test) == 0: break
    
#score is proportion of correctly assigned markers
print "%.10f"%(float(total) / total_markers)
