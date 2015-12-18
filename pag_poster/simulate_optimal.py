#!/usr/bin/python

#
# sample one "optimal" ordering assuming perfect error correction
# and imputation, output one reconstructed map
# assumes only 1 lg is present
#

import sys
import random

fmap = sys.argv[1]
floc = sys.argv[2]
iters = int(sys.argv[3])

#load error free, complete loci data
f = open(floc)
f.readline()
f.readline()
nmarkers = int(f.readline().strip().split()[2])
nsamples = int(f.readline().strip().split()[2])

markers = {}

for line in f:
    tok = line.strip().split()
    uid = tok[0]
    mtype = tok[1]
    orig_phase = tok[2]
    
    conv = {'0':0,'1':1,'-':0} #convert phase '-' to 0
    phase = [conv[tok[2][1]],conv[tok[2][2]]]
    data = tok[3:]
    
    orig_data = data[:]
    
    #convert to binary representation
    if mtype == '<lmxll>':
        conv = {'ll':'0-','lm':'1-'}
        data = [conv[x] for x in data]
    elif mtype == '<nnxnp>':
        conv = {'nn':'-0','np':'-1'}
        data = [conv[x] for x in data]
    else:
        assert mtype == '<hkxhk>'
        conv = {'hh':'00','hk':'01','kh':'10','kk':'11'}
        data = [conv[x] for x in data]
        
    #convert to phased representation
    conv = [{'-':'-','0':'0','1':'1'},{'-':'-','0':'1','1':'0'}]
    for i in xrange(len(data)):
        data[i] = conv[phase[0]][data[i][0]] + conv[phase[1]][data[i][1]]
    
    assert not uid in markers
    markers[uid] = [uid,mtype,phase,data,orig_phase,orig_data]
f.close()

#get correct ordering from the map file
order = []

f = open(fmap)
f.readline()
for line in f:
    tok = line.strip().split()
    uid = tok[0]
    order.append(uid)

f.close()

olist = range(nmarkers-1)

for ctr in xrange(iters):
    random.shuffle(olist)

    for x in olist[:len(olist)/2]:
        #consider markers at current positions x and x+1
        uid1 = order[x]
        uid2 = order[x+1]
        
        #get the two genotype representations
        data1 = markers[uid1][3]
        data2 = markers[uid2][3]
        
        #are there any recombs between the two markers?
        flag = False
        for i in xrange(nsamples):
            if data1[i][0] != '-' and data2[i][0] != '-':
                if data1[i][0] != data2[i][0]:
                    flag = True
                    break
            if data1[i][1] != '-' and data2[i][1] != '-':
                if data1[i][1] != data2[i][1]:
                    flag = True
                    break

        #recombination found, do not swap
        if flag: continue
        
        #perform the swap
        order[x],order[x+1] = order[x+1],order[x]

print 'name = POPNAME'
print 'popt = CP'
print 'nloc = %d'%nmarkers
print 'nind = %d'%nsamples
print '; group 000 markers %d'%nmarkers

for uid in order:
    m = markers[uid]
    print '%s %s %s '%(m[0],m[1],m[4]) + ' '.join(m[5])
