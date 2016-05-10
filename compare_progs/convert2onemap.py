#!/usr/bin/python

'''
convert joinmap format into onemap format
hkxhk == B3.7
lmxll == D1.10
nnxnp == D2.15
'''

import sys

inp = sys.argv[1]
nmarkers = int(sys.argv[2])
nsamples = int(sys.argv[3])

f = open(inp)

print "%d %d"%(nsamples,nmarkers)

conv =\
{
    "<hkxhk>":"B3.7 ",
    "<lmxll>":"D1.10",
    "<nnxnp>":"D2.15",
}

conv2=\
{
    "ll":"a",
    "lm":"ab",
    "nn":"a",
    "np":"ab",
    "hh":"a",
    "hk":"ab",
    "kk":"b",
    "--":"-",
}

for line in f:
    tok = line.strip().split()
    name = tok[0]
    mtype = conv[tok[1]]
    #phase = tok[2] #ignore phase
    data = tok[3:]
    
    print "*%s %s "%(name,mtype) + ','.join([conv2[x] for x in data])
    
f.close()
