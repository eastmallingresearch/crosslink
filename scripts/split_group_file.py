#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
'''
split a loc file which contains comments denoting LGS into
one file per LG
'''

import sys

inp = sys.argv[1]
outbase = sys.argv[2]

fout = None
f = open(inp)

#skip joinmap header if present
peek = f.readline()
if peek.startswith('name'):
    assert f.readline().startswith('popt')
    assert f.readline().startswith('nloc')
    assert f.readline().startswith('nind')
else:
    #rewind file
    f.seek(0,0)
    
for line in f:
    if line.startswith(';'):
        #close any previous file
        if fout: fout.close()
        
        #extract lg information, open new file
        tok = line.strip().split()
        assert tok[1] == 'group'
        assert tok[3] == 'markers'
        fout = open(outbase+tok[2]+'.loc','wb')
        continue
        
    #treat as marker data
    assert fout != None
    fout.write(line)

f.close()
if fout: fout.close()
