#!/usr/bin/python

# break a linkage group after a given marker

#break_linkage_group.py inputfile markername output1 output2

import sys

inp = sys.argv[1]
uid = sys.argv[2]
out1 = sys.argv[3]
out2 = sys.argv[4]

data=[]
f = open(inp)

for line in f:
    if line.startswith(';'): continue #skip header
    
    tok = line.strip().split()
    data.append(tok)
    
    if tok[0] == uid:
        fout = open(out1,'wb')
        fout.write('; group NONE markers %d\n'%len(data))
        for row in data: fout.write(' '.join(row) + '\n')
        fout.close()
        data = []

f.close()

fout = open(out2,'wb')
fout.write('; group NONE markers %d\n'%len(data))
for row in data: fout.write(' '.join(row) + '\n')
fout.close()

