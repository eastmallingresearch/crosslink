#!/usr/bin/python
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
'''
match up LGs between two maps based on the numbers of shared markers
also work out if map orientations are reversed
'''

import argparse

ap = argparse.ArgumentParser(description=__doc__,formatter_class=argparse.ArgumentDefaultsHelpFormatter)
ap.add_argument('--inp',default=None,type=str,help='input map file')
ap.add_argument('--ref',default=None,type=str,help='reference map file')
ap.add_argument('--out',default=None,type=str,help='output file showing which reference LG each input LG corresponds to, and whether orientation is reversed')
ap.add_argument('--out2',default=None,type=str,help='output file showing merger candidates')
conf = ap.parse_args()

import sys
import math
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

#work out which input lg corresponds to which reference lg
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
    if len(posn_info[lg]) == 1:
        corr[lg] = 0.0
    else:
        corr[lg] = np.cov(np.array(posn_info[lg]).T)[0][1]

#create sorted conversion information
olist = [[origlg,newlg,str(corr[origlg] < 0.0)] for origlg,newlg in conv.iteritems()]

olist.sort(key=lambda x:imap.lgdict[x[0]].markers,reverse=True) #minor sort by input lg size
olist.sort(key=lambda x:x[1])                    #major sort by ref lg name

#output conversion information
fout = open(conf.out,'wb')
for x in olist: fout.write(','.join(x) + '\n')
fout.close()

#output candidates for merging
minfo = {}
for origlg,newlg in conv.iteritems():
    if not newlg in minfo: minfo[newlg] = []
    minfo[newlg].append(origlg)
    
fout = open(conf.out2,'wb')
for newlg in minfo:
    if len(minfo[newlg]) < 2: continue
    fout.write(' '.join(minfo[newlg]) + '\n')
fout.close()
