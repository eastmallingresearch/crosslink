#!/usr/bin/python

#
# assign markers from the OLD version of the pipeline to linkage groups
# based on the old pipeline + joinmap lg assignments
#

import sys

#which lg were the probesets in in the previous map?
lg_info = sys.argv[1]

#markers from the old pipeline
markers_file = sys.argv[2]

#base name for output files
outbase = sys.argv[3]

#assign probeset ids to a linkage group
#according to previous map
ps2lg = {}
lgname = None
f = open(lg_info)
for line in f:
    if line.startswith(';'): continue
    tok = line.strip().split()
    if len(tok) == 0: continue
    
    if line.startswith('group'):
        lgname = tok[1]
        continue
        
    psid = tok[0].split('-')[1].split(':')[0]
    #print psid,lgname
    
    assert lgname != None
    assert psid not in ps2lg
    ps2lg[psid] = lgname
f.close()


#assign markers to lgs
fout = {}
f = open(markers_file)
for i in xrange(4): f.readline()
for line in f:
    tok = line.strip().split()
    psid = tok[0].split('-')[1].split(':')[0]
    
    if not psid in ps2lg: continue
    
    lg = ps2lg[psid]
    
    fname = outbase + '_' + lg + '.loc'
    #print fname
    
    if not fname in fout: fout[fname] = open(fname,'wb')
    
    fout[fname].write(line)
    
f.close()

for fname in fout: fout[fname].close()
