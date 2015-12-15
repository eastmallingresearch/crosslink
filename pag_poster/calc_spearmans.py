#!/usr/bin/python

'''
compare two map orders
first order is treated as the correct one
assumes one lg only
output magnitude of spearmans/pearsons
multiplied by the fraction of the true markers which are in the reconstructed order
incase some markers were left out
also output the proportion of true markers in the reconstruction
'''

import sys
from scipy.stats import spearmanr
from scipy.stats import pearsonr

order1 = sys.argv[1]
order2 = sys.argv[2]

#file columns: marker name, cm position
f = open(order1)
list1 = [line.strip().split() for line in f]
f.close()

f = open(order2)
list2 = [line.strip().split() for line in f]
f.close()

marker = {}

for i,x in enumerate(list1): marker[x[0]] = [x[1],None]
for i,x in enumerate(list2):
    if not x[0] in marker: continue
    marker[x[0]][1] = x[1]

sharedlist = [[marker[x][0],marker[x][1]] for x in marker]
sharedlist = [x for x in sharedlist if not None in x]
sharedlist = [[float(x[0]),float(x[1])] for x in sharedlist]

#proportion of markers in the reconstructed lg
prop = float(len(sharedlist)) / float(len(list1))

#spearmans score
sp = abs(spearmanr(sharedlist)[0]) * prop

#pearsons score
pe = abs(pearsonr([x[0] for x in sharedlist],[x[1] for x in sharedlist])[0]) * prop

print sp,pe,prop
