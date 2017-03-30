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

#convert a crosslink outcross loc file into maternal and paternal backcross encoded mstmap files


import sys

inp = sys.argv[1]
phasefile = sys.argv[2]
matfile = sys.argv[3]
patfile = sys.argv[4]

template='''population_type DH
population_name POPNAME
distance_function haldane
cut_off_p_value 1.0
no_map_dist 999999.0
no_map_size 0
missing_threshold 1.0
estimation_before_clustering no
detect_bad_data no
objective_function COUNT
number_of_loci %d
number_of_individual %d
'''

#load phase info
phase_dict = {}
f = open(phasefile)
for line in f:
    tok = line.strip().split()
    mid = tok[0]
    phase = tok[2]
    phase_dict[mid] = phase[1:-1] #chop off { and }
f.close()

#count markers and samples
n_mat = 0
n_pat = 0
n_samples = 0
f = open(inp)
for line in f:
    tok = line.strip().split()
    mtype = tok[1]
    n_samples = len(tok) - 3
    
    if mtype == '<lmxll>':
        n_mat += 1
    if mtype == '<hkxhk>':
        n_mat += 1
        n_pat += 1
    if mtype == '<nnxnp>':
        n_pat += 1
f.close()

#print headers
fmat = open(matfile,'wb')
fpat = open(patfile,'wb')

fmat.write(template%(n_mat,n_samples*2) + '\n')
fpat.write(template%(n_pat,n_samples*2) + '\n')

fmat.write('locus_name\t' + '\t'.join([str(x) for x in xrange(n_samples*2)]) + '\n')
fpat.write('locus_name\t' + '\t'.join([str(x) for x in xrange(n_samples*2)]) + '\n')

f = open(inp)
for line in f:
    tok = line.strip().split()
    mid = tok[0]
    mtype = tok[1]
    phase = phase_dict[mid]
    
    calls = tok[3:]

    if mtype == '<lmxll>':
        if   phase[0] == '0': conv = {'ll':'A-','lm':'B-','--':'--'}
        elif phase[0] == '1': conv = {'ll':'B-','lm':'A-','--':'--'}
        else:                 assert False
    elif mtype == '<nnxnp>':
        if   phase[1] == '0': conv = {'nn':'-A','np':'-B','--':'--'}
        elif phase[1] == '1': conv = {'nn':'-B','np':'-A','--':'--'}
        else:                 assert False
    elif mtype == '<hkxhk>':
        if   phase == '00': conv = {'hh':'AA','hk':'--','kh':'--','kk':'BB','--':'--'}
        elif phase == '01': conv = {'hh':'AB','hk':'--','kh':'--','kk':'BA','--':'--'}
        elif phase == '10': conv = {'hh':'BA','hk':'--','kh':'--','kk':'AB','--':'--'}
        elif phase == '11': conv = {'hh':'BB','hk':'--','kh':'--','kk':'AA','--':'--'}
        else:               assert False
    else:
        assert False, "unknown marker type %s"%mtype

    if mtype == '<lmxll>' or mtype == '<hkxhk>':
        fmat.write(mid)
        for x in calls:
            y = conv[x]
            fmat.write('\t' + y[0] + '\t' + y[1])
        fmat.write('\n')

    if mtype == '<nnxnp>' or mtype == '<hkxhk>':
        fpat.write(mid)
        for x in calls:
            y = conv[x]
            fpat.write('\t' + y[0] + '\t' + y[1])
        fpat.write('\n')
    
f.close()
fmat.close()
fpat.close()
