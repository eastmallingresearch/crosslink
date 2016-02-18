#!/usr/bin/python

'''
reinsert redundant markers into a map file
does not alter or update any map positions
simply inserts all redundant markers at the same position as their associated framework marker
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--inp',default=None,type=str,help='nonredundant map file')
ap.add_argument('--redun',default=None,type=str,help='file matching redundant markers to their nonredundant representative')
conf = ap.parse_args()

import sys

#map from nonredundant uid to associated redundant uids
uid2red = {}
f = open(conf.redun)
for line in f:
    tok = line.strip().split()
    redun = tok[0]
    uid = tok[1]
    if not uid in uid2red: uid2red[uid] = []
    uid2red[uid].append(redun)
f.close()

#process the nonredundant ordered markers
#insert redundant markers after their associated framework marker
f = open(conf.inp)
for line in f:
    if line.startswith('group'): continue #filter out grouping headers - will need to be regenerated
    tok = line.strip().split('\t')
    uid = tok[0]
    print line,                       #output nonredundant marker
    if not uid in uid2red: continue   #no associated redundant markers
    
    #output all associated redundant markers
    for ruid in uid2red[uid]:
        print '\t'.join([ruid] + tok[1:])
f.close()
