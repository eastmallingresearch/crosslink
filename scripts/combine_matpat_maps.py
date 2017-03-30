#!/usr/bin/python

#
# calculate combined map positions from separate maternal and paternal map positions
# using interpolation and extrapolation (same method as main crosslink programs)
# usage: combine_matpat_maps.py input.tsv > output.tsv
# input.tsv first three columns must be: markername maternalposition paternalposition
# use NA for missing values
# first line is ignored
#

import sys

inp = sys.argv[1]
markers = []
missing = None

#load data, count shared markers, average shared positions
n_shared = 0
f = open(inp)
f.readline()

for line in f:
    tok = line.strip().split('\t')
    uid = tok[0]
    
    if tok[1] == 'NA': mpos = missing
    else:              mpos = float(tok[1])
    
    if tok[2] == 'NA': ppos = missing
    else:              ppos = float(tok[2])
    
    if mpos != missing and ppos != missing:
        n_shared += 1
        spos = (mpos + ppos) / 2.0
        mtype = 'HK'
    else:
        spos = missing
        if mpos == missing: mtype = 'NP'
        else:               mtype = 'LM'
    
    markers.append([uid,mtype,mpos,ppos,spos])
f.close()

#must have at least two shared markers
assert n_shared >= 2

n_markers = len(markers)

#interpolate / extrapolate positions of lm / np markers based on flanking hk marker(s)
for x in [2,3]: #maternal or paternal positions
    
    #sort by maternal or paternal order
    markers.sort(key=lambda y:y[x])
    prevhk = None
    nexthk = None
    
    #find last hk in the lg
    for i in xrange(n_markers-1,-1,-1):
        m = markers[i]
        if m[1] == 'HK':
            lasthk = m
            break
    
    assert lasthk != None
    
    for i in xrange(0,n_markers):
        m = markers[i]
        if m[x] == missing: continue
        
        #remember previous hk
        if m[1] == 'HK':
            prevhk = m
            nexthk = None
            continue
        
        #find next hk (if any)
        if nexthk == None and prevhk != lasthk:
            for j in xrange(i+1,n_markers):
                m2 = markers[j]
                
                if m2[1] == 'HK':
                    nexthk = m2
                    break
        
        if prevhk == None:
            #before first hk: extrapolate
            m[4] = m[x] - nexthk[x] + nexthk[4]
            
        elif nexthk == None:
            #after last hk: extrapolate
            m[4] = m[x] - prevhk[x] + prevhk[4]
            
        else:
            #inbetween two hks: interpolate
            m[4] = m[x] - prevhk[x]
            
            if nexthk[x] - prevhk[x] > 0.0: #avoid div by zero of pos prev == next
                m[4] /= nexthk[x] - prevhk[x]
            
            m[4] *= nexthk[4] - prevhk[4]
            m[4] += prevhk[4]

#sort by combined map position
markers.sort(key=lambda y:y[4])
offset = markers[0][4]

#print results
fmt = '%.3f'
for m in markers:
    #ensure first position is zero
    m[4] -= offset
    
    if m[2] == missing: mpos = 'NA'
    else:               mpos = fmt%m[2]
    
    if m[3] == missing: ppos = 'NA'
    else:               ppos = fmt%m[3]
    
    print m[0] + '\t' + mpos  + '\t' + ppos + '\t' + fmt%m[4]
