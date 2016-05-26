#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
'''
reinsert redundant markers into a loc file
does not generate an updated group header
does not adjust phasing or hk imputation
simply inserts all redundant markers after their associated framework marker
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--inp',default=None,type=str,help='nonredundant loci file')
ap.add_argument('--all',default=None,type=str,help='loci file containing all markers')
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

#load all loci, redundant and nonredundant, ignore any group headers
markers = {}
f = open(conf.all)
for line in f:
    tok = line.strip().split()
    uid = tok[0]
    assert not uid in markers
    markers[uid] = line
f.close()

#process the nonredundant ordered markers
#insert redundant markers after their associated framework marker
f = open(conf.inp)
for line in f:
    tok = line.strip().split()
    uid = tok[0]
    print line,                       #output nonredundant marker
    if not uid in uid2red: continue   #no associated redundant markers
    
    #output all associated redundant markers
    for ruid in uid2red[uid]:
        print markers[ruid],
f.close()
