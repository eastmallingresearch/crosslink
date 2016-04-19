#!/usr/bin/python

#
# calculate a score for accuracy of cross lg marker detection
#

import sys
import glob

if len(sys.argv) < 3:
    print "usage: calc_crosslg_accuracy.py <crosslg_list> '<map_log_glob>'"
    exit(0)

markers = {}
f = open(sys.argv[1])
for line in f:
    uid = line.strip().split()[0]
    markers[uid] = True
f.close()

errors = len(markers)
corrected = 0
false = 0
for fname in glob.glob(sys.argv[2]):
    f = open(fname)
    for line in f:
        if not 'homeo' in line: continue
        uid = line.strip().split()[1]
        if uid in markers: corrected +=1
        else:              false += 1
    f.close()

if errors == 0:
    #score decreases with increasing number of false corrections
    score = 1.0 / (1.0 + 10.0*false)
else:
    #score increases with increasing number of true corrections
    #score decreases with increasing number of false corrections
    score = corrected / float(errors)
    score *= float(errors) / (errors + 10.0*false)

print "%.5lf"%score
