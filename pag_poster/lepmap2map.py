#!/usr/bin/python

#
# convert lepmap output into normal map file
#

import sys

lep = sys.argv[1]
loc = sys.argv[2]

#get names of markers from loc file
f = open(loc)
for x in xrange(4): f.readline()#skip header
names = [line.strip().split()[0] for line in f]#get marker names in file order
f.close()

#convert lepmap file
f = open(lep)
for line in f:
    if line.startswith('#'): continue
    tok = line.strip().split()
    marker = names[int(tok[0])-1]
    pos = (float(tok[1]) + float(tok[2])) / 2.0
    print marker,pos
f.close()
