#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# modify marker type of some markers
#

import sys

if len(sys.argv) != 4:
    print "usage: modify_markers.py INPUT_MARKERS MAT2PATFILE PAT2MATFILE > OUTPUT_MARKERS"
    exit()

inpname = sys.argv[1]
m2pname = sys.argv[2]
p2mname = sys.argv[3]

m2p = {'ll':'nn','lm':'np', '--':'--'}
p2m = {'nn':'ll','np':'lm', '--':'--'}

mat2pat = {}
f = open(m2pname)
for line in f:
    uid = line.strip()
    mat2pat[uid] = True
f.close()

pat2mat = {}
f = open(p2mname)
for line in f:
    uid = line.strip()
    pat2mat[uid] = True
f.close()

f = open(inpname)
for line in f:
    tok = line.strip().split()
    uid = tok[0]
    
    if (not uid in mat2pat) and (not uid in pat2mat):
        print line,
        continue
    
    if uid in mat2pat:
        assert not uid in pat2mat
        tok[1] = '<nnxnp>'
        tok[2] = '{'+tok[2][2]+tok[2][1]+'}'
        tok[3:] = [m2p[x] for x in tok[3:]]
        
    if uid in pat2mat:
        assert not uid in mat2pat
        tok[1] = '<lmxll>'
        tok[2] = '{'+tok[2][2]+tok[2][1]+'}'
        tok[3:] = [p2m[x] for x in tok[3:]]
        
    print ' '.join(tok)
    
f.close()
