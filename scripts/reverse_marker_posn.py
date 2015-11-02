#!/usr/bin/python

'''
reverse the digits of the map positions embedded inthe marker names
so that it is impossible for joinmap to produce an alphabetically sorted list
of markers which is also in perfect map order
in case this somehow helps it produce better orderings
'''

import sys

for line in sys.stdin:
    tok = line.strip().split()
    
    tok[0] = tok[0][0] + tok[0][-2:0:-1] + tok[0][-1]
    
    for x in tok: print x+' ',
    print
