#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
'''
rename and reorient LGs based on similarity to an existing map
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--inp',default=None,type=str,help='input map file')
ap.add_argument('--ref',default=None,type=str,help='reference map file')
ap.add_argument('--out',default=None,type=str,help='output map file')
ap.add_argument('--conv',default=None,type=str,help='output file detailing how the lg names have changed and whether a flip was performed')
conf = ap.parse_args()

import sys
import numpy as np
from mapping_funcs import *

imap = genmap(conf.inp)
vmap = genmap(conf.ref)

lg_info = {}

posn_info = {}

#for each marker in imap
for uid in imap.mkdict.iterkeys():
    #find which input map lg this marker is in
    lg = imap.mkdict[uid].lg
    
    #find which reference lg this marker is in
    if not uid in vmap.mkdict: continue
    vlg = vmap.mkdict[uid].lg
    
    #record both positions
    if not lg in posn_info: posn_info[lg] = []
    posn_info[lg].append([imap.mkdict[uid].posn,vmap.mkdict[uid].posn])
    
    #update info for this lg
    if not lg in lg_info: lg_info[lg] = {}
    if not vlg in lg_info[lg]: lg_info[lg][vlg] = 0
    lg_info[lg][vlg] += 1

#work out which input lg maps to which reference lg
#according to which ref lg has the most hits for each input lg
conv = {}
for lg in lg_info.iterkeys():
    lg_list = [[key,val] for key,val in lg_info[lg].iteritems()]
    lg_list.sort(key=lambda x:x[1])
    conv[lg] = lg_list[-1][0]

#work out covariance
#between input and reference positions
#to decide whether to flip the LG or not
corr = {}
for lg in posn_info.iterkeys():
    corr[lg] = np.cov(np.array(posn_info[lg]).T)[0][1]
    #corr[lg] = np.corrcoef(np.array(posn_info[lg]).T)[0][1]

data = imap.data

#flip lgs with negative covariance with homologous vesca lg
for row in data:
    if corr[row[1]] < 0.0: row[2] = imap.lgdict[row[1]].size - row[2]

data.sort(key=lambda x:x[2])
data.sort(key=lambda x:x[1])
data.sort(key=lambda x:conv[x[1]])

#output new map
fout = open(conf.out,'wb')
for row in data: fout.write( row[0] + ',' + conv[row[1]] + ',' + str(row[2]) + '\n' )
fout.close()

#output conversion information
fout = open(conf.conv,'wb')
for origlg,newlg in conv.iteritems():
    fout.write(origlg + ',' + newlg + ',' + str(corr[origlg] < 0.0) + '\n')
fout.close()
