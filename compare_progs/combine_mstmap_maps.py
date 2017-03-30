#!/usr/bin/python

#
# combine two mstmap maps into a single file
# input: two mstmap output files
# output: one map file with marker, mat, pat, shared positions
# treats everything as being from a single linkage group
# outputs markers in no particular order
#

import sys

markers = {}

files = sys.argv[1:3]

for i in xrange(2): #maternal positions file, paternal positions file
    f = open(files[i])
    for line in f:
        line = line.strip()
        if line.startswith(';') or line.startswith('group') or line == '': continue
        tok = line.split()
        uid = tok[0]
        pos = float(tok[1])
        
        if not uid in markers: markers[uid] = [None,None]
        markers[uid][i] = pos
        
    f.close()

fmt = '%.3f'
for uid in markers:
    m = markers[uid]

    if m[0] == None: mpos = 'NA'
    else:            mpos = fmt%m[0]

    if m[1] == None: ppos = 'NA'
    else:            ppos = fmt%m[1]
    
    print uid + '\t' + mpos + '\t' + ppos + '\tNA'
