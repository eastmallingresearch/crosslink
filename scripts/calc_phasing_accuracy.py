#!/usr/bin/python

#
# find proportion of markers placed in correct linkage groups
# AND phased correctly
#

import sys

if len(sys.argv) < 2:
    print "usage: calc_phasing_accuracy.py <original_loci> <test_loci> [<test_loci>...]"
    exit(0)

#load original markers
orig = []
total_markers = 0
f = open(sys.argv[1])
for line in f:
    if line.startswith(';'):
        orig.append({})
        continue
    tok = line.strip().split()
    uid = tok[0]
    phase = tok[2][1:-1]
    
    orig[-1][uid] = phase
    total_markers += 1
f.close()
    
#load markers being tested
test = []
for fname in sys.argv[2:]:
    f = open(fname)
    for line in f:
        if line.startswith(';'):
            test.append({})
            continue
        tok = line.strip().split()
        uid = tok[0]
        phase = tok[2][1:-1]
        test[-1][uid] = phase
    f.close()
    
orig.sort(key=lambda x:len(x),reverse=True)
test.sort(key=lambda x:len(x),reverse=True)

#for each original lg, by decreasing size
#find the test lg with most markers from it, assign this as "correct" and then remove it
#count total markers in the "correct" lg
total_errors = 0
total_count = 0
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
            
    #test[best_i] == lg (from orig)
    #check mat/pat phasing
    for x in [0,1]:
        errors=0
        count=0
        for uid in test[best_i].iterkeys():
            if uid in lg:
               if lg[uid][x] == '-': continue
               count += 1
               if test[best_i][uid][x] !=  lg[uid][x]: errors += 1
               
        if errors > count / 2: total_errors += count - errors  #treat as antiphase
        else:                  total_errors += errors
        
        total_count += count
            
    del test[best_i]
    
    if len(test) == 0: break
    
#score is proportion of correctly assigned markers
print "%.10f"%(float(total_errors) / total_count)
