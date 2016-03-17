#!/usr/bin/python

'''
find the combined length of maternal and paternal maps
print results to std in integer units (for bash scripts)
'''

import sys

inp = sys.argv[1]

maxval = [0.0,0.0]

f = open(inp)
for line in f:
    if line.startswith('group'): continue #skip header
    tok = line.strip().split()[1:]
    
    for i in xrange(2):
        if tok[i] != 'NA':
            val = float(tok[i])
            if val > maxval[i]: maxval[i] = val
f.close()

print int(sum(maxval)*1000.0)
