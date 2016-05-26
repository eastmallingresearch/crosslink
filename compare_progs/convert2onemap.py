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
convert joinmap format into onemap format
hkxhk == B3.7
lmxll == D1.10
nnxnp == D2.15
'''

import sys

inp = sys.argv[1]
nmarkers = int(sys.argv[2])
nsamples = int(sys.argv[3])

f = open(inp)

print "%d %d"%(nsamples,nmarkers)

conv =\
{
    "<hkxhk>":"B3.7 ",
    "<lmxll>":"D1.10",
    "<nnxnp>":"D2.15",
}

conv2=\
{
    "ll":"a",
    "lm":"ab",
    "nn":"a",
    "np":"ab",
    "hh":"a",
    "hk":"ab",
    "kk":"b",
    "--":"-",
}

for line in f:
    tok = line.strip().split()
    name = tok[0]
    mtype = conv[tok[1]]
    #phase = tok[2] #ignore phase
    data = tok[3:]
    
    print "*%s %s "%(name,mtype) + ','.join([conv2[x] for x in data])
    
f.close()
