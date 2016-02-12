#!/usr/bin/python

#
# measure how many markers were placed in correct linkage groups
#

import sys

if len(sys.argv) < 2:
    print "usage: calc_grouping_accuracy.py <correctly_grouped_loci> <test_loci> [<test_loci>...]"
    exit(0)

orig = []
total_markers = 0

f = open(sys.argv[1])
for line in f:
    if line.startswith(';'):
        orig.append({})
        continue
    uid = line.strip().split()[0]
    orig[-1][uid] = True
    total_markers += 1
f.close()
    

test = []
for fname in sys.argv[2:]:
    f = open(fname)
    for line in f:
        if line.startswith(';'):
            test.append({})
            continue
        uid = line.strip().split()[0]
        test[-1][uid] = True
    f.close()
    
orig.sort(key=lambda x:len(x),reverse=True)
test.sort(key=lambda x:len(x),reverse=True)

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
    
print float(total) / total_markers
