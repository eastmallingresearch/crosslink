import cPickle,os,random,math,inspect
from math import log10
import numpy as np

def calc_lod_rf_f2(data):
    '''
    use C to quickly calculate rf and LOD
    '''
    
    #output marker data as block of characters
    fout = open('tmp/tmp_marker_rf_lod','wb')
    conv = {'aa':'A','ab':'H','bb':'B','-':'-'}
    lgs = {}
    for row in data:
        fout.write(''.join([conv[x] for x in row[3]]))
        lgs[row[1]] = True
    fout.close()
    
    n_lgs = len(lgs)
    
    n_markers = len(data)
    n_samples = len(data[0][3])
    
    #calc rf and LOD
    assert os.system("./scripts/calc_rf_lod_f2 tmp/tmp_marker_rf_lod %d %d > tmp/tmp_rf_lod_out"%(n_markers,n_samples)) == 0

    #read back in the values
    rf_lod = np.zeros([n_markers,n_markers])
    f = open('tmp/tmp_rf_lod_out')
    for i,line in enumerate(f): rf_lod[i,:] = [float(x) for x in line.strip().split()]
    f.close()
    
    lod = np.zeros([n_markers,n_markers])
    for i in xrange(n_lgs-1):
        for j  in xrange(i+1,n_lgs):
            lod[j][i] = lod[i][j] = rf_lod[j][i]
            rf_lod[j][i] = rf_lod[i][j]
            
    return rf_lod,lod
    
def seek_csv(f,fname,uid,comment='#',header=1,sep=','):
    '''
    position the file at the first location of the requested uid 
    if uid is None return the header
    '''
    
    if not os.path.isfile(fname):
        raise "file not found: %s"%fname
    
    findex = fname + '.pickleindex'
    redo_index = False
    
    if os.path.isfile(findex):
        #check index is not older than the data file itself
        if os.path.getmtime(findex) < os.path.getmtime(fname):
            print 'stale index for',fname
            redo_index = True
    else:
        #no index, create one
        print 'no index for',fname
        redo_index = True
    
    #(re)make index if required
    if redo_index: index_csv(f,fname,comment,header,sep)
        
    fidx = open(findex)
    header,uid_index = cPickle.load(fidx)
    fidx.close()
    
    #return header
    if uid == None: return header
        
    #position file at firstr occurrence of requested uid
    f.seek(uid_index[uid])

def index_csv(f,fname,comment='#',header=1,sep=','):
    '''
    index a csv/tsv file based on first occurrence of the uids in the first column
    '''
    
    linect = 0
    header_lines = []
    uid_index = {}
    f.seek(0)
    nextposn = f.tell()
    print 'indexing',fname
    while True:
        rawline = f.readline()
        if rawline == '': break #end of file
        currposn = nextposn
        nextposn = f.tell()
        line = rawline.strip()
        if comment and line.startswith(comment): continue #skip comments
        if line == '': continue #ignore blank lines
        linect += 1
        if header != None and linect <= header:
            header_lines.append(line.split(sep)) #store header
            continue
        uid = line.split(sep)[0]
        if not uid in uid_index:
            uid_index[uid] = currposn    
        
    print 'done'
    #test index
    #f.seek(0)
    #for uid in uid_index.iterkeys():
    #    f.seek(uid_index[uid])
    #    chk = f.readline().strip().split(sep)[0]
    #    if chk != uid: print "failed:",chk,uid
    
    if len(header_lines) == 1:
        header = header_lines[0]
    else:
        header = header_lines

    fout = open(fname+'.pickleindex','wb')
    cPickle.dump([header,uid_index],fout,1)
    fout.close()

def save_onemap(d1,d2,b3,names,fname):
    '''
    save into onemap format
    '''
    
    fout = open(fname,'wb')

    #write header
    fout.write(str(len(names)) + ' ' + str(len(d1)+len(d2)+len(b3)) + '\n')

    #write markers
    for x in d1:
        fout.write('*' + x[0] + ' D1.10 ')
        fout.write(','.join([str(y) for y in x[3]])+ '\n')
    
    for x in d2:
        fout.write('*' + x[0] + ' D2.15 ')
        fout.write(','.join([str(y) for y in x[3]])+ '\n')
    
    for x in b3:
        fout.write('*' + x[0] + ' B3.7 ')
        fout.write(','.join([str(y) for y in x[3]])+ '\n')
    
    fout.close()

'''
def calc_lod(row1,row2,rf):
    'calc a LOD for an F2'
    
    genos = []
    for j in xrange(len(row1)):
        #skip missing data
        if '-' in row1[j] or '-' in row2[j]: continue
        genos.append(row1[j]+row2[j])
        
    N = len(genos)
'''

def est_rf(row1,row2,iters=50):
    '''
    estimate rf for an F2 using EM
    from Principles of Statistical Genomics, Xu, S. (docs/recomb_frac_chapter.pdf)
    '''
    
    #extract the genotypes as pairs
    genos = []
    for j in xrange(len(row1)):
        #skip missing data
        if '-' in row1[j] or '-' in row2[j]: continue
        genos.append(row1[j]+row2[j])
    
    #number of samples without missing data
    n = len(genos)
    
    #count the observable genotypes
    m11 = genos.count('aaaa')
    m21 = genos.count('abaa')
    m31 = genos.count('bbaa')
    m12 = genos.count('aaab')
    m22 = genos.count('abab')
    m32 = genos.count('bbab')
    m13 = genos.count('aabb')
    m23 = genos.count('abbb')
    m33 = genos.count('bbbb')
    
    #count number of 1 and 2 recombinations
    n1 = m12 + m21 + m23 + m32
    n2 = m13 + m31
    
    #see Principles of Statistical Genomics, Xu, S. (docs/recomb_frac_chapter.pdf)
    #p21
    
    #find rf using EM
    r = 0.5
    for j in xrange(iters):
        E = r**2 * m22 / (r**2 + (1.0 - r)**2)
        r = (2.0 * (E + n2) + n1) / (2.0 * n)
        
    return r

def est_rf2(row1,row2,iters=100):
    '''
    estimate rf for an F2 using EM
    alternative formulation
    also calculate LOD
    
    N = total gametes
    R = recombinant gametes
    S = N - R
    r = recomb fraction
    s = 1 - r
    
    LR = L(r=/hat r) / L(r=1/2) =  (s^S * r^R) / (0.5^N)
    LOD = log10(LR)
    
    from genetic mapping in experimental populations
    section 3.3 (F2)
    '''
    
    #extract the genotypes as pairs
    genos = []
    for j in xrange(len(row1)):
        #skip missing data
        if '-' in row1[j] or '-' in row2[j]: continue
        genos.append(row1[j]+row2[j])
    
    #number of samples without missing data
    n = len(genos)
    
    #count the observable genotypes, number of crossovers
    m11 = genos.count('aaaa') #0
    m21 = genos.count('abaa') #1
    m31 = genos.count('bbaa') #2
    m12 = genos.count('aaab') #1
    m22 = genos.count('abab') #0 or 2
    m32 = genos.count('bbab') #1
    m13 = genos.count('aabb') #2
    m23 = genos.count('abbb') #1
    m33 = genos.count('bbbb') #0

    #count number of 1 and 2 recombination genotypes
    n1 = m12 + m21 + m23 + m32
    n2 = m13 + m31

    #find rf using EM
    r = 0.5
    for j in xrange(iters):
        #E = pre * m22, ie the number of 2 crossover events from class m22
        E = m22 * r**2 / (r**2 + (1.0 - r)**2)
        r = (2.0 * (E + n2) + n1) / (2.0 * n)

    R = 2.0 * (E + n2) + n1
    N = 2.0 * n
    S = N - R
    s = 1.0 - r

    print r,s,R,S,N
    #print math.log10(2.0**N * s**S * r**R)
    #NB r**R = 1.0 if R == 0
    #therefore log10(r**R) == 0.0
    LOD = N * log10(2.0)
    if s > 0.0: LOD += S * log10(s) 
    if r > 0.0: LOD += R * log10(r) 
    
    return r,LOD   #,LODalt

def save_csvr(names,data,fname):
    '''
    save map data in Rqtl csvr format
    '''
    
    if type(fname) == str:
        fout = open(fname,'wb')
    else:
        fout = fname

    #write header
    fout.write('markers,,,' + ','.join(names) + '\n')

    #write markers
    for x in data:
        fout.write(','.join([str(y) for y in x[:3]]) + ',')
        fout.write(','.join([str(y) for y in x[3]])+ '\n')
    
    if type(fname) == str:
        fout.close()

def size_sort_lgs(data):
    '''
    sort lgs by size (number of markers)
    renumber of lgs accordingly
    '''
    
    lgs = []
    lg = None
    
    for x in data:
        if x[1] != lg: lgs.append([])
        lgs[-1].append(x)
        
    lgs.sort(key=lambda x:len(x), reverse=True)
    
    data = []
    
    for i,lg in enumerate(lgs):
        for row in lg:
            row[1] = i
            data.append(row)
        
    return data


def orderby_mstmap(data,fname):
    '''
    order markers by mstmap output
    '''
    
    #index of marker positions
    posn = {}

    #read in map order
    lg = 0
    lgs = []
    f = open(fname)
    for line in f:
        line = line.strip()
        if line.startswith(';'): continue
        if line == '': continue
        
        if line.startswith('group lg'):
            lg += 1
            lgs.append([])
            continue
            
        
        tok = line.split('\t')
        marker = tok[0]
        cm = float(tok[1])
        
        posn[marker] = [lg,cm]
    f.close()

    #update lg and cm
    for i,x in enumerate(data):
        marker = x[0]
        x[1] = posn[marker][0]
        x[2] = posn[marker][1]

    #sort markers by new map order
    data.sort(key=lambda x:float(x[2]))
    data.sort(key=lambda x:int(x[1]))
    
    #make lg numbers negative (to avoid conflicting with existing lg numbers)
    for i,x in enumerate(data): x[1] = -x[1]

def save_mstmap(data,names,header,fname):
    '''
    save data in mstmap format
    '''

    header2 =\
    '''number_of_loci                 %d
    number_of_individual           %d

    '''

    fout = open(fname,'wb')
    nmarkers = len(data)
    nindiv = len(names)
    fout.write(header)
    fout.write(header2%(nmarkers,nindiv))
    fout.write('locus_name\t' + '\t'.join(names) + '\n')
    for x in data: fout.write(x[0] + '\t' + '\t'.join(x[3]) + '\n')
    fout.close()

def mstmap_order(names,data,lg,
                 conv=None,#mapping to convert genotype codes into mstmap format
                 mstmap='mstmap',#suitable path to mstmap binary
                 poptype='DH',#DH or RILn, n>=2 I think
                 distfunc='kosambi', # or haldane
                 objfunc='COUNT', #COUNT=sum of recombination, ML=maximum likelihood
                 tmpdir='tmp',
                 randomize=False, #randomise marker order before passing to mstmap
                 suppressoutput=True #whether to hide mstmap's stdout
                 ):
    '''
    use mstmap to reorder markers in a single lg only
    
    save data from one lg in mstmap format
    converting genotype codes if required
    order using mstmap
    load output and reorder markers using new order
    see http://alumni.cs.ucr.edu/~yonghui/mstmap.html
    for more info on mstmap
    '''

    #get rid of spaces in sample names
    #(does not modify names in calling function)
    names = [x.replace(' ','_') for x in names]

    conf  = 'population_type %s\n'%poptype
    conf += 'population_name POPNAME\n'
    conf += 'distance_function %s\n'%distfunc
    conf += 'cut_off_p_value 1.0\n' #do not split into groups using pvalue
    conf += 'no_map_dist 999999.0\n' #do not split using map distance
    conf += 'no_map_size 0\n' #do not exclude small lgs
    conf += 'missing_threshold 1.0\n' #do not filter markers with missing data
    conf += 'estimation_before_clustering no\n' #do not estimate missing data
    conf += 'detect_bad_data no\n' #do not correct bad data
    conf += 'objective_function %s\n'%objfunc

    #get just the markers for the required lg
    lgdata = [row for row in data if row[1] == lg]
    if randomize: random.shuffle(lgdata)
    nmarkers = len(lgdata)
    nindiv = len(names)

    conf += 'number_of_loci %d\n'%nmarkers
    conf += 'number_of_individual %d\n\n'%nindiv

    #write data to temporary file
    fname = tmpdir + '/' + 'tmp_mstmap_input_%06d.txt'%random.randint(0,999999)
    fout = open(fname,'wb')
    fout.write(conf)
    fout.write('locus_name\t' + '\t'.join(names) + '\n')
    for row in lgdata:
        if conv:
            genos = [conv[x] for x in row[3]] #convert genotype codes
        else:
            genos = row[3] #retain existing codes
            
        fout.write(row[0] + '\t' + '\t'.join(genos) + '\n')
    fout.close()

    #order markers using mstmap, output to a temporary file
    cmd = mstmap + ' ' + fname + ' ' + fname + '.out'
    if suppressoutput: cmd += ' > /dev/null' #hide stdout
    assert os.system(cmd) == 0

    #read in new map positions from mstmap output file
    posn = read_mstmap_order(fname+'.out')
    
    #update the centimorgan position for all the markers sent to mstmap
    for row in lgdata:
        if row[0] in posn:
            row[2] = posn[row[0]][1]
            
    #markers now need to be ordered into order
    #using:
    #data.sort(key=lambda x:x[2])
    #data.sort(key=lambda x:x[1])
    #will not do it here incase further lgs are to be (re)ordered first

def read_mstmap_order(fname):
    '''
    read in map position information from mstmap output file
    '''
    
    #index of marker positions
    posn = {}

    #read in map order
    lg = 0
    lgs = []
    f = open(fname)
    for line in f:
        line = line.strip()
        if line.startswith(';'): continue
        if line == '': continue
        
        if line.startswith('group lg'):
            lg += 1
            lgs.append([])
            continue
        
        tok = line.split('\t')
        marker = tok[0]
        cm = float(tok[1])
        
        posn[marker] = [lg,cm]
    f.close()
    
    return posn
    
def convert_markers(data,conv):
    '''
    convert markers from one format to another
    '''
    
    for i,x in enumerate(data):
        data[i][3] = [conv[x] for x in data[i][3]]
        

def load_csvr(fname):
    '''
    load csvr style Rqtl file
    
    return column names and data
    '''
    
    f = open(fname)

    #get individual names, ignore lg and cm cols
    header = f.readline().strip().split(',')
    
    assert header[0] == 'markers'
    assert header[1] == ''
    assert header[2] == ''
    #assert header[3] != ''
    
    names = header[3:]
    
    data = []

    #load in marker data
    for line in f:
        tok = line.strip().split(',')
        marker = tok[0]
        lg = int(tok[1])
        cm = float(tok[2])
        calls = tok[3:]
        
        data.append([marker,lg,cm,calls])
    f.close()
    
    return names,data

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
