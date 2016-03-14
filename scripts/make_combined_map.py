#!/usr/bin/python

#
# merge separate linkage group map files into a single map
# output only the combined map position
# where combined map positions are not available for a linkage group
# use whichever parental position is available
# the lg name is assumed to be in the filename from the first underscore to the next dot (exclusive)
# ignores lines starting with 'group'
#
# usage: make_combined_map.py map_file [map_file...] > output_map
#

import sys
import os

#for each filename given on the command line
for fname in sys.argv[1:]:
    #sys.stderr.write(fname + '\n')

    #extract the presumed linkage group name
    lgname = os.path.basename(fname)[:-4]
    
    mat=True
    pat=True
    com=True
    
    #parse data into memory
    data = []
    f = open(fname)
    for line in f:
        if line.startswith('group'): continue #ignore any file header starting with 'group'
        tok = line.strip().split()
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
    for tok in data: print ','.join([tok[0],lgname,tok[i]])
