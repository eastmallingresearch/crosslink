#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# count how many markers had a type error
# and proportion that were corrected accurately
#

import sys

if len(sys.argv) < 3:
    print "usage: calc_typeerr_accuracy.py <typeerr_list> <group_log>"
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
f = open(sys.argv[2])
for line in f:
    if not 'type corrected' in line: continue
    uid = line.strip().split()[3]
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
