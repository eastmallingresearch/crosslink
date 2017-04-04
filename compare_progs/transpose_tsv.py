#!/usr/bin/python

'''
transpose tsv so that columns headings become row headings
'''

import sys
import numpy as np

data = np.transpose(np.genfromtxt(sys.argv[1],dtype=object,delimiter='\t'))

np.savetxt(sys.stdout,data,fmt='%s',delimiter='\t')
