#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#
# adjust lg names and orientations to match a reference map
# allowing for more than one lg to match any given reference lg
#

# usage: cl_adjustlgs3.py INPDIR REFMAP OUTDIR

import sys
import os
import glob
import numpy as np
from scipy.stats.stats import pearsonr

inpdir = sys.argv[1]
refmap = sys.argv[2]
outdir = sys.argv[3]

inpfiles = glob.glob(inpdir + '/*.map')

inplgs = {}

lginfo = {}
#for each map file
for fname in inpfiles:
    mat=True
    pat=True
    com=True
    
    #parse data into memory
    data = []
    f = open(fname)
    for line in f:
        if line.startswith('group'): continue #ignore any file header starting with 'group'
        tok = [x.strip() for x in line.strip().split()]
        assert len(tok) == 4 #file columns are assumed to be: markername matpos patpos compos
        if tok[1] == 'NA': mat = False
        if tok[2] == 'NA': pat = False
        if tok[3] == 'NA': com = False
        data.append(tok)
    f.close()
    
    #we must be able to use one of the three map positions for the whole lg
    assert True in [mat,pat,com]
    
    #figure out which column contains the best map position
    if com == True:
        i = 3
    elif pat == True:
        i = 2
    else:
        i = 1
        
    #output
    lg = fname.split('/')[-1].replace('.map','')
    inplgs[lg] = { tok[0]:float(tok[i]) for tok in data }
    
    #find max map position for mat, pat and combined maps
    lginfo[lg] = [None,None,None]
    
    pos = [float(tok[1]) for tok in data if tok[1] != 'NA']
    if len(pos) > 0: lginfo[lg][0] = max(pos)
        
    pos = [float(tok[2]) for tok in data if tok[2] != 'NA']
    if len(pos) > 0: lginfo[lg][1] = max(pos)
        
    pos = [float(tok[3]) for tok in data if tok[3] != 'NA']
    if len(pos) > 0: lginfo[lg][2] = max(pos)

reflgs = {}

f = open(refmap)
for line in f:
    uid,lg,pos = line.strip().split(',')
    if not lg in reflgs: reflgs[lg] = {}
    reflgs[lg][uid] = float(pos)
    
f.close()

match2ref = {}
ref2match = {}
for lg in inplgs:
    
    #find best match for lg amongst ref lgs
    best = 0
    for lg2 in reflgs:
        count = 0
        for uid in inplgs[lg]:
            if uid in reflgs[lg2]:
                count += 1
                
        if count > best:
            best = count
            match2ref[lg] = lg2
           
    if best == 0:
        #no hits at all, do not rename
        match2ref[lg] = None
        continue
           
    lg2 = match2ref[lg]
    if not lg2 in ref2match: ref2match[lg2] = []
    ref2match[lg2].append([lg,best])
    
#assign new names to lgs
for lg in ref2match:
    ref2match[lg].sort(key=lambda x:x[1],reverse=True)
    
    for i,x in enumerate(ref2match[lg]):
        orig = x[0]
        new = lg
        if i > 0:
            new += '.%d'%(i+1)
        match2ref[orig] = new

#decide whether to invert the lgs
flip = {}
for lg in match2ref:
    flip[lg] = False
    
    if match2ref[lg] == None:
        continue #no match, leave alone
    
    lg2 = match2ref[lg].split('.')[0] #get name of matching ref lg
    
    xx = []
    yy = []
    for uid in inplgs[lg]:
        if not uid in reflgs[lg2]:
            continue
            
        xx.append(inplgs[lg][uid])
        yy.append(reflgs[lg2][uid])
    
    if len(xx) < 2:
        corr = 1.0
    elif np.std(xx) == 0.0 or np.std(yy) == 0.0:
        corr = 1.0
    else:
        corr = pearsonr(xx,yy)[0]
    
    if corr < 0.0:
        print lg,lg2,'flip'
        flip[lg] = True
    else:
        print lg,lg2,'no flip'

#create output files using new names, inverting order if required        
for lg in match2ref:
    src = inpdir + '/' + lg + '.loc'    
    f = open(src)
    data = [line for line in f]
    f.close()

    if flip[lg]: data = data[-1::-1]

    if match2ref[lg] == None:
        dst = outdir + '/orig_' + lg + '.loc'
    else:
        dst = outdir + '/' + match2ref[lg] + '.loc'
    
    fout = open(dst,'wb')
    for line in data: fout.write(line)
    fout.close()

#adjust maps
for lg in match2ref:
    src = inpdir + '/' + lg + '.map'    
    f = open(src)
    data = []
    for line in f:
        if line.startswith('group'): continue
        tok = [x.strip() for x in line.strip().split('\t')]
        data.append(tok)
    f.close()

    if flip[lg]:
        data = data[-1::-1]
        for i,tok in enumerate(data):
            #print len(tok),tok
            #print lg,lginfo[lg]
            if tok[1] != 'NA': tok[1] = str(lginfo[lg][0] - float(tok[1]))
            if tok[2] != 'NA': tok[2] = str(lginfo[lg][1] - float(tok[2]))
            if tok[3] != 'NA': tok[3] = str(lginfo[lg][2] - float(tok[3]))

    if match2ref[lg] == None:
        dst = outdir + '/orig_' + lg + '.map'
    else:
        dst = outdir + '/' + match2ref[lg] + '.map'
    
    fout = open(dst,'wb')
    for tok in data: fout.write('\t'.join(tok) + '\n')
    fout.close()
