#!/usr/bin/python

#
# count how many markers had a type error
# and proportion that were corrected accurately
#

import sys

if len(sys.argv) < 2:
    print "usage: calc_typeerr_accuracy.py <correctly_typed_loci> <corrected_loci> [<corrected_loci>...]"
    exit(0)

#load correctly typed markers
orig = {}
f = open(sys.argv[1])
for line in f:
    if line.startswith(';'): continue
    tok = line.strip().split()
    uid = tok[0]
    mtype = tok[1]
    orig[uid] = mtype
f.close()

nmarkers = len(orig)
    
#load corrected markers, count typing errors
nerrors=0
for fname in sys.argv[2:]:
    f = open(fname)
    for line in f:
        if line.startswith(';'): continue
        tok = line.strip().split()
        uid = tok[0]
        mtype = tok[1]
        if orig[uid] != mtype: nerrors += 1
    f.close()
    
print "%.10f"%(float(nerrors) / nmarkers)
