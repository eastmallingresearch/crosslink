#!/usr/bin/python

'''
create some cross linkage group hkxhk markers
pick lmxll and nnxnp markers not on the same linkage group
fuse them into single hkxhk markers

also create some marker typing errors
do this after creating cross linkage group markers
'''

import sys
import random
from scipy.stats import binom

mapfile = sys.argv[1]
locfile = sys.argv[2]
pcross = float(sys.argv[3])  #prob create a cross linkage group marker
perr = float(sys.argv[4])  #prob switch type between lmxll and nnxnp

markers = {'<lmxll>':{},'<nnxnp>':{}}
nmarkers = 0

#load map, store by lg and marker type
f = open(mapfile)
for line in f:
    #eg: M0000006f <lmxll> {0-} 0 1.150901
    #<name> <type> <phase> <linkage_group> <position>
    if line.startswith('#'): continue
    nmarkers += 1
    tok = line.strip().split()
    assert len(tok) == 5
    
    mtype = tok[1]
    lg = tok[3]
    
    if mtype not in ['<lmxll>','<nnxnp>']: continue #ignore hkxhk markers
    
    if not lg in markers[mtype]: markers[mtype][lg] = []
    markers[mtype][lg].append(tok)
f.close()

#must have at least two linkage groups available for both marker types
assert len(markers['<lmxll>']) > 1 and len(markers['<nnxnp>']) > 1

#pick marker pairs to be fused
pairs = []
n = random.randrange(binom.rvs(nmarkers,pcross))
for i in xrange(n):
    #pick lmxll from any lg
    nlgs = len(markers['<lmxll>'])
    assert nlgs > 0
    lg = random.randrange(nlgs)
    lgname = markers['<lmxll>'].keys()[lg]
    nmks = len(markers['<lmxll>'][lgname])
    j = random.randrange(nmks)
    marker = markers['<lmxll>'][lgname][j]
    pairs.append([marker])
    del markers['<lmxll>'][lgname][j]
    if len(markers['<lmxll>'][lgname]) == 0: del markers['<lmxll>'][lgname]
    
    #pick nnxnp from different lg
    nlgs = len(markers['<nnxnp>'])
    if lgname in markers['<nnxnp>']: nlgs -= 1
    assert nlgs > 0
    
    while True:
        lg = random.randrange(nlgs)
        lgname2 = markers['<nnxnp>'].keys()[lg]
        if lgname2 != lgname: break
        
    nmks = len(markers['<nnxnp>'][lgname2])
    j = random.randrange(nmks)
    marker = markers['<nnxnp>'][lgname2][j]
    pairs[-1].append(marker)
    del markers['<nnxnp>'][lgname2][j]
    if len(markers['<nnxnp>'][lgname2]) == 0: del markers['<nnxnp>'][lgname2]

#verify linkage groups are different, store names of fusing markers
fout = open('crossmarkers_list','wb')
data = {}
for x in pairs:
    assert x[0][3] != x[1][3]
    data[x[0][0]] = None
    data[x[1][0]] = None
    fout.write(x[0][0]+'\n')
fout.close()

#load existing genotype data for fusing markers
f = open(locfile)
for line in f:
    if line[0] in ['#',';']: continue
    tok = line.strip().split()
    name = tok[0]
    if name in data: data[name] = tok
f.close()

#perform fusion
fused = {}
for x in pairs:
    lmname = x[0][0]
    npname = x[1][0]

    fused[lmname] = [lmname,'<hkxhk>','{00}'] #assuming unphased data
    fused[npname] = None
    for i in xrange(3,len(data[lmname])):
        if '--' in [data[lmname][i],data[npname][i]]:
            fused[lmname].append('--')
        elif data[lmname][i] == 'lm':
            if data[npname][i] == 'np':
                fused[lmname].append('kk')
            else:
                fused[lmname].append('hk')
        else:
            if data[npname][i] == 'np':
                fused[lmname].append('hk')
            else:
                fused[lmname].append('hh')
        
#output modified data, replace lm marker with fused marker, remove np marker
switch = {'lm':'np', 'll':'nn', 'np':'lm', 'nn':'ll', '--':'--'}

fout = open('typeerrmarkers_list','wb')
f = open(locfile)
for line in f:
    if line[0] in ['#',';']: continue
    tok = line.strip().split()
    name = tok[0]
    mtype = tok[1]
    
    if name in fused:
        if fused[name] != None:
            print ' '.join(fused[name])
        continue
        
    elif mtype != '<hkxhk>':
        if random.random() < perr:
            fout.write(name+'\n')
            if mtype == '<lmxll>':
                line = name + ' <nnxnp> ' + tok[2] + ' '
            else:
                line = name + ' <lmxll> ' + tok[2] + ' '
            line += ' '.join([switch[x] for x in tok[3:]]) + '\n'
        
    print line,
    if name in data: data[name] = tok
f.close()
fout.close()
