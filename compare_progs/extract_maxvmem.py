#!/usr/bin/python

#
# prepare maxvmem capture file for loading into R / ggplot
#

import sys

inpfile = sys.argv[1]
f = open(inpfile)
for line in f:
    #eg cl_approx_1_1096723436:32649216.000000
    tok = line.strip().split('_')
    tok = ['_'.join(tok[:-2]),tok[-2],tok[-1]]
    
    prog = tok[0]
    density = tok[1]
    maxvmem = tok[-1].split(':')[-1]
    
    if float(maxvmem) == 0.0: continue #erroneous reporting of zero mem usage!
    
    print ' '.join([prog,density,maxvmem])
f.close()
