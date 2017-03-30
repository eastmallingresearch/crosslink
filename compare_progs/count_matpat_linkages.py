#!/usr/bin/python

#Crosslink
#Copyright (C) 2016  NIAB EMR
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along
#with this program; if not, write to the Free Software Foundation, Inc.,
#51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#contact:
#robert.vickerstaff@emr.ac.uk
#Robert Vickerstaff
#NIAB EMR
#New Road
#East Malling
#WEST MALLING
#ME19 6BJ
#United Kingdom


'''
count above threshold linkages to same versus other type markers
'''

import sys

locfile = sys.argv[1]
rffile = sys.argv[2]

markers = {}
f = open(locfile)
for line in f:
    tok = line.strip().split()
    uid = tok[0]
    mtype = tok[1]

    markers[uid] = [mtype,0,0]
f.close()

_type = [None,'<lmxll>','<nnxnp>','<hkxhk>']

f = open(rffile)
for line in f:
    tok = line.strip().split()
    uid1 = tok[0]
    mtype1 = _type[int(tok[1])]
    uid2 = tok[2]
    mtype2 = _type[int(tok[3])]
    rf = float(tok[4])
    lod = float(tok[5])

    if mtype1 == '<hkxhk>': continue
    if mtype2 == '<hkxhk>': continue

    m1 = markers[uid1]
    assert mtype1 == m1[0]
    
    m2 = markers[uid2]
    assert mtype2 == m2[0]
    
    if mtype2 == mtype1: #increment count of same-type linkages
        m1[1] += 1
        m2[1] += 1
    else:                #increment count of other-type linkages
        m1[2] += 1
        m2[2] += 1
f.close()

for uid in markers:
    if markers[uid][0] == '<hkxhk>': continue
    print uid, markers[uid][0], markers[uid][1], markers[uid][2]
