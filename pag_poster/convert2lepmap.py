#!/usr/bin/python

'''
convert joinmap format into lepmap2 format
see http://sourceforge.net/p/lepmap2/wiki/Modules/
columns are tab separated
"Columns 1-6 are family name, individual name, father, mother, sex, and phenotype"
indivname: must be an integer
father/mother: 0 for unknown
sex:1=male 2=female
phenotype:set to zero
two allele codes per genotype column, space separated
0 0 => missing data
1 1 => aa
1 2 => ab etc

this script outputs the data in transposed format (one marker per line)
run transpose_tsv.py to convert into final form
'''

import sys

inp = sys.argv[1]
#out = sys.argv[2]

f = open(inp)
f.readline()
f.readline()
nmarkers = int(f.readline().strip().split()[2])
nsamples = int(f.readline().strip().split()[2])

print '\t'.join(['family']*(nsamples+2))                  #population name
print '\t'.join([str(x) for x in xrange(1,nsamples+3)])   #sample uids
print '\t'.join(['0','0'] + ['1']*(nsamples))   #id of the father
print '\t'.join(['0','0'] + ['2']*(nsamples))   #id of the mother
print '\t'.join(['1','2'] + ['0']*(nsamples))   #sex of the sample
print '\t'.join(['0','0'] + ['0']*(nsamples))   #dummy phenotype

#one line per marker
for line in f:
    tok = line.strip().split()
    name = tok[0]
    mtype = tok[1]
    #seg = tok[2]
    data = tok[3:]
    
    if   mtype == '<hkxhk>':
        conv = {'hh':'1 1','hk':'1 2','kh':'1 2','kk':'2 2','--':'0 0'}
        pat = '1 2'
        mat = '1 2'
    elif mtype == '<lmxll>':
        conv = {'ll':'1 1','lm':'1 2','--':'0 0'}
        pat = '1 1'
        mat = '1 2'
    elif mtype == '<nnxnp>':
        conv = {'nn':'1 1','np':'1 2','--':'0 0'}
        pat = '1 2'
        mat = '1 1'
    else:
        assert False
    
    print '\t'.join([pat,mat]+[conv[x] for x in data])
f.close()
