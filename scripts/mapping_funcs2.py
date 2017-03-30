#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

class group(object):
    def __init__(self,uid):
        'create an empty linkage group'
        self.uid = uid
        self.size = 0.0
        self.markers = {}
        self.order = None

    def add(self,item):
        'add marker to this linkage group'
        self.markers[item.uid] = item
        if item.pos > self.size: self.size = item.pos

class marker(object):
    def __init__(self,uid,lg,pos):
        'create one marker'
        self.uid = uid
        self.lg = lg
        self.pos = pos
        self.relpos = None

class loadmap(object):
    def __init__(self,fname,order=None):
        'load map'

        f = open(fname)

        self.loci = {}
        self.groups = {}
        self.order = []

        #load in marker data
        for line in f:
            tok = line.strip().split(',')
            uid = tok[0]
            lg = tok[1]
            pos = float(tok[2])

            assert pos >= 0.0
            assert not uid in self.loci
            
            if not lg in self.groups:
                self.groups[lg] = group(lg)
                self.order.append(lg)

            m = marker(uid,lg,pos)
            self.loci[uid] = m
            self.groups[lg].add(m)
            
        f.close()
        
        if order == None:
            #sort by lg name
            self.order.sort()
        else:
            #follow the given order
            self.order = order
            
        #assign each lg its position in the list
        for lg in self.groups:
            self.groups[lg].order = self.order.index(lg)
            
        #calc relative position of each marker
        for uid in self.loci:
            mk = self.loci[uid]
            lg = self.groups[mk.lg]
            if lg.size > 0.0:
                mk.relpos = mk.pos / lg.size
            else:
                assert mk.pos == 0.0
                mk.relpos = 0.0
