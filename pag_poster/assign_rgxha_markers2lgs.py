#!/usr/bin/python

#
# assign markers from the new version of the pipeline to linkage groups
# based on the old pipeline + joinmap lg assignments
#

import sys

#which lg were the probesets in in the previous map?
lg_info = sys.argv[1]

#how were probesets (redundancy-)grouped in the previous map?
ps_groups = [sys.argv[2],sys.argv[3]]

#how are probeset ids assigned to snp ids
ps2snp_file = sys.argv[4]

#markers from the current pipeline
markers_file = sys.argv[5]

#base name for output files
outbase = sys.argv[6]

#assign probeset ids to a linkage group
#according to previous map
ps2lg = {}
lgname = None
f = open(lg_info)
for line in f:
    if line.startswith(';'): continue
    tok = line.strip().split()
    if len(tok) == 0: continue
    
    if line.startswith('group'):
        lgname = tok[1]
        continue
        
    psid = tok[0].split('-')[1].split(':')[0]
    #print psid,lgname
    
    assert lgname != None
    assert psid not in ps2lg
    ps2lg[psid] = lgname
f.close()

#load probeset to SNP id information
ps2snp = {}
snp2ps = {}
f = open(ps2snp_file)
f.readline()
for line in f:
    tok = line.strip().split()
    psid = tok[0].split('-')[1]
    snpid = tok[1].split('-')[1]
    
    assert psid not in ps2snp
    ps2snp[psid] = snpid
    if not snpid in snp2ps: snp2ps[snpid] = []
    snp2ps[snpid].append(psid)
f.close()

#print snp2ps
#exit()

#load probeset grouping info
ps_grp = {}
for fname in ps_groups:
    f = open(fname)
    f.readline()
    for line in f:
        tok = line.strip().split()

        #first probeset if defines the group
        main_id = tok[0].split(':')[0].split('-')[1]
        assert main_id not in ps_grp
        ps_grp[main_id] = main_id
        
        #all other probeset ids belong to the group
        for x in tok[1:]:
            ps_id = x.split(':')[0].split('-')[1]
            assert ps_id not in ps_grp
            ps_grp[ps_id] = main_id
    f.close()

#print ps_grp

#assign markers to lgs
fout = {}
f = open(markers_file)
for i in xrange(4): f.readline()
for line in f:
    tok = line.strip().split()
    psid = tok[0].split('-')[1]
    
    main_id = None
    if psid in ps_grp:
        main_id = ps_grp[psid]
    elif psid in ps2snp:
        for x in snp2ps[ps2snp[psid]]:
            if x in ps_grp:
                main_id = ps_grp[x]
                break
                
    if main_id == None: continue
    
    if not main_id in ps2lg: continue
    
    lg = ps2lg[main_id]
    
    fname = outbase + '_' + lg + '.loc'
    #print fname
    
    if not fname in fout: fout[fname] = open(fname,'wb')
    
    fout[fname].write(line)
    
f.close()

for fname in fout: fout[fname].close()
