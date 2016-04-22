import os,random,math,inspect
from math import log10
import numpy as np

class lgrec(object):
    '''
    linkage group record object
    
    offset = 0-based position of LG in list of LGs
    size = total size in cM
    start = position of start of LG in terms of cumulative map length
    markers = number of markers
    '''
    def __init__(self,name=None,offset=None,size=None,start=None,markers=None):
        args, dummy, dummy, vals = inspect.getargvalues(inspect.currentframe())
        for x in args: self.__dict__[x] = vals[x]

class mkrec(object):
    '''
    marker record object
    '''
    def __init__(self,name=None,lg=None,posn=None,cumposn=None,calls=[]):
        args, dummy, dummy, vals = inspect.getargvalues(inspect.currentframe())
        for x in args: self.__dict__[x] = vals[x]

class genmap(object):
    def __init__(self,fname,sort=False,markerfilter=None):
        '''
        load csvr style Rqtl file of genetic map with optional marker data
        does not assume lgs are numerical
        '''
        
        f = open(fname)

        self.names = []
        
        self.data = []

        #load in marker data
        for line in f:
            tok = line.strip().split(',')
            marker = tok[0]
            if markerfilter: marker = markerfilter(marker)
            
            lg = tok[1]
            cm = float(tok[2])
            
            assert cm >= 0.0
            
            calls = tok[3:]
            
            self.data.append([marker,lg,cm,calls])
        f.close()
        
        #sort by lg and position
        if sort:
            self.data.sort(key=lambda x:x[2])
            self.data.sort(key=lambda x:x[1])

        self.lglist = [] #record order of first mention of each lg
        self.lgdict = {} #lg info index by lg name
        self.mkdict = {} #index of marker names

        for i,row in enumerate(self.data):
            marker = row[0]
            lg = row[1]
            cm = row[2]
            
            self.mkdict[marker] = mkrec(name=marker,lg=lg,posn=cm)

            #update list of lg names
            if not lg in self.lgdict:
                x = lgrec(name=lg,offset=len(self.lglist),size=0.0,start=0.0,markers=0)
                self.lgdict[lg] = x
                self.lglist.append(x)
            
            #update lg size
            if self.lgdict[lg].size == None or cm > self.lgdict[lg].size:
                self.lgdict[lg].size = cm
                
            #update marker count
            self.lgdict[lg].markers += 1
            
        #calc lg cumulative start position
        cumsize = 0.0
        for i,rec in enumerate(self.lglist):
            rec.start = cumsize
            cumsize += rec.size

        #calc marker cumulative position
        for marker,rec in self.mkdict.iteritems():
            rec.cumposn = rec.posn + self.lgdict[rec.lg].start
            
        self.nmarkers = len(self.data)
        self.nindivs = len(self.names)
