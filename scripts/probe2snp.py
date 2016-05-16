#!/usr/bin/python

#
# convert probeset ids to snp ids in a csv
# usage: probe2snp.py probe2snpfile inp.csv > out.csv
#

import sys

p2sname = sys.argv[1]
inp = sys.argv[2]


p2s = {}
f = open(p2sname)
f.readline() #skip header
for line in f:
    tok = line.strip().split()
    pid = tok[0]
    sid = tok[1]
    p2s[pid] = sid
f.close()

f = open(inp)
for line in f:
    tok = line.strip().split(',')
    for i,x in enumerate(tok):
        if x in p2s:
            tok[i] = p2s[x]
            
    print ','.join(tok)
f.close()
