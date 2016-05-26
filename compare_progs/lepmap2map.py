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

#
# convert lepmap output into normal map file
#

import sys

lep = sys.argv[1]
loc = sys.argv[2]

#get names of markers from loc file
f = open(loc)
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
