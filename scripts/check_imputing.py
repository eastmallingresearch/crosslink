#!/usr/bin/python

#
# count imputing errors
#

import sys

f1 = open(sys.argv[1]) #original
f2 = open(sys.argv[2]) #with missing
f3 = open(sys.argv[3]) #imputed

total = 0
errors = 0

while True:
    line1 = f1.readline()
    line2 = f2.readline()
    line3 = f3.readline()
    
    if line1 == '' or line2 == '' or line3 == '': break

    tok1 = line1.strip().split()
    tok2 = line2.strip().split()
    tok3 = line3.strip().split()
    
    for i in xrange(3,len(tok1)):
        if tok2[i] != '--': continue
        total += 1
        
        if tok3[i] != tok1[i]:
            #print tok1[i],'-->',tok3[i]
            errors += 1
            
print '#imputing errors', errors, float(errors)/total
