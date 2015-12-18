#!/usr/bin/python

#
# convert 10.0 in fourth column to 0.1
# ie correct the density value
#

import sys
import glob

for fname in glob.glob('./compare_progs/compare_*_*_0.1_*_*_stats'):
    f = open(fname)
    line = f.readline().strip()
    f.close()
    
    if line == '': continue #empty file
    
    tok = line.split()
    
    if tok[3] != '10.0': continue #density not given as 10.0
    
    tok[3] = '0.1' #correct value
    
    #overwrite original file
    #print fname + ' '.join(tok)
    fout = open(fname,'wb')
    fout.write(' '.join(tok) + '\n')
    fout.close()
