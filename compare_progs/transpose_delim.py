#!/usr/bin/python

'''
transpose tsv so that columns headings become row headings
'''

import sys
import numpy as np

inp=sys.argv[1]
delim=sys.argv[2]

data = np.transpose(np.genfromtxt(inp,dtype=object,delimiter=delim))

np.savetxt(sys.stdout,data,fmt='%s',delimiter=delim)
