#include "crosslink_group.h"
#include "crosslink_utils.h"

//decode the marker category first letters and weights from the string
//format is: one letter code followed by weight as exactly two digits
//first two characters are the default weight as two digits
//weights can be {00,01,...99}, converted to integers {0,1,...99}
//letter code is the case sensitive first character of the marker name
//eg 01P03
// means each marker scores 1, except markers whose name starts with a capital P which score 3
struct weights*decode_weights(char*weight_str)
{
    int ret;
    unsigned i;
    struct weights*w=NULL;
    
    assert(w = calloc(1,sizeof(struct weights)));
    
    assert(strlen(weight_str) >= 2);
    
    w->n = (strlen(weight_str)-2) / 3;
    
    assert(strlen(weight_str) == 3*w->n + 2);
    
    assert(w->tag = calloc(w->n,sizeof(char)));
    assert(w->weight = calloc(w->n+1,sizeof(unsigned)));
    
    //extract first-characters, break into substrings with NULLs
    for(i=0; i<w->n; i++)
    {
        w->tag[i] = weight_str[2 + i * 3];
        weight_str[2 + i * 3] = '\0';
    }
    
    //extract default weight, store as last weight
    ret = sscanf(weight_str,"%u",&(w->weight[w->n]));
    assert(ret == 1);
    
    //extract weights
    for(i=0; i<w->n; i++)
    {
        ret = sscanf(&(weight_str[3 + i * 3]),"%u",&(w->weight[i]));
        assert(ret == 1);
    }
    
    return w;
}

/*
fix marker types
where strong linkage exists between LM and NP markers take this to indicate
that the parental genotypes were wrong, and that the marker type should be
switched between LM <=> NP
form trees excluding hk markers
where a tree ends up with a minority of the other type of marker (eg a few LMs in an NP tree)
switch the type of the minority to the majority
*/
void fix_marker_types(struct conf*c,struct lg*p,struct earray*ea,struct weights*w)
{
    unsigned i,j,ntrees,ctr,changes;
    unsigned*lmct=NULL;
    unsigned*npct=NULL;
    struct marker*curr=NULL;
    struct marker*prev=NULL;
    //double min_lod_used=-1.0;
    struct edge*e=NULL;
    struct marker*m=NULL;
    
    //initialise to disconnected forest, ignore hks
    ntrees = 0;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        
        //each marker begins in its own group with no attached edges
        m->uf_parent = m;
        m->uf_rank = 1;

        //ignore hk markers
        if(m->type != HKTYPE) ntrees += 1;
    }

    //union find into trees
    for(i=0; i<ea->nedges && ntrees>1; i++)
    {
        e = ea->array[i];
        
        //ignore if edge involves an hk marker
        if(e->m1->type == HKTYPE || e->m2->type == HKTYPE) continue;
        
        if(union_groups(e->m1,e->m2))
        {
            ntrees -= 1;
            //min_lod_used = e->lod;
        }
    }
    
    assert(lmct = calloc(ntrees,sizeof(unsigned)));
    assert(npct = calloc(ntrees,sizeof(unsigned)));
    
    //sort markers by tree grouping
    qsort(p->array,p->nmarkers,sizeof(struct marker*),mcomp_func);
    
    //count lms and nps in each tree
    curr = NULL;
    prev = NULL;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        if(m->type == HKTYPE) continue;
        
        //keep track of which tree we are looking at
        curr = find_group(m);
        if(prev == NULL)
        {
            ctr = 0;
        }
        else if(curr != prev)
        {
            ctr += 1;
        }
        
        prev = curr;
        
        //find which category j the marker belongs to
        //default category is w->n
        for(j=0; j<w->n; j++) if(m->name[0] == w->tag[j]) break;
        
        //create weighted count of lms and nps in the current tree
        if(m->type == LMTYPE) lmct[ctr] += w->weight[j];
        else                  npct[ctr] += w->weight[j];
    }
    
    //for(i=0; i<ntrees; i++) printf("group %u lmct=%u npct=%u\n",i,lmct[i],npct[i]);
        
    curr = NULL;
    prev = NULL;
    changes = 0;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        if(m->type == HKTYPE) continue;
        
        //keep track of which tree we are looking at
        curr = find_group(m);
        if(prev == NULL)
        {
            ctr = 0;
        }
        else if(curr != prev)
        {
            ctr += 1;
        }
        
        prev = curr;
        
        //convert to most common marker type in the current tree
        //if tied, choose lm arbitrarily
        if(lmct[ctr] < npct[ctr])
        {
            //tree is assumed to be NP
            if(m->type == LMTYPE)
            {
                //convert lm -> np
                m->type = NPTYPE;
                m->oldphase[1] = m->oldphase[0];
                m->phase[1] = m->phase[0];
                m->data[1] = m->data[0];
                m->bits[1] = m->bits[0];
                m->mask[1] = m->mask[0];
                m->orig[1] = m->orig[0];
                m->data[0] = NULL;
                m->bits[0] = NULL;
                m->mask[0] = NULL;
                m->orig[0] = NULL;
                changes += 1;
                
                if(c->flog) fprintf(c->flog,"#linkage group %s, %s LM->NP\n",p->name,m->name);
            }
        }
        else
        {
            //tree is assumed to be LM
            if(m->type == NPTYPE)
            {
                //convert np -> lm
                m->type = LMTYPE;
                m->oldphase[0] = m->oldphase[1];
                m->phase[0] = m->phase[1];
                m->data[0] = m->data[1];
                m->bits[0] = m->bits[1];
                m->mask[0] = m->mask[1];
                m->orig[0] = m->orig[1];
                m->data[1] = NULL;
                m->bits[1] = NULL;
                m->mask[1] = NULL;
                m->orig[1] = NULL;
                changes += 1;
                
                if(c->flog) fprintf(c->flog,"#linkage group %s, %s NP->LM\n",p->name,m->name);
            }
        }
    }
    
    //flag any remaining edges between a mat and a pat marker with a negative lod
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];
        
        if(e->m1->type == HKTYPE || e->m2->type == HKTYPE) continue;
        if(e->m1->type == e->m2->type) continue;
        
        e->lod = -1000.0;
    }
    
    //sort edges by LOD, negative LODs go at the end
    qsort(ea->array,ea->nedges,sizeof(struct edge*),ecomp_func);
    
    //ignore negative lod edges
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];
        
        if(e->lod < 0.0)
        {
            ea->nedges = i; //not actually freeing them D:
            break;
        }
    }

    if(c->flog) fprintf(c->flog,"#linkage group %s, type fixing resolved %u groups, %u marker type(s) changed\n",p->name,ntrees,changes);
}

/*
imputing missing genotype calls using kNN method
note: hk calls have their data set to missing but may not be actually missing
therefore look at orig to decide if that call is actually missing
rather than just being an hk that is not imputed yet
*/
void impute_missing(struct conf*c,struct lg*p,struct earray*ea)
{
    struct marker*m=NULL;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    struct edge*e=NULL;
    unsigned i,j,k,x;
    double rf,dval;
    
    //create missing value imputation data structures
    impute_alloc(c,p->nmarkers,p->array);
    
    //scan edge list (ie list of significant marker-marker linkages)
    //update m->miss info
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];
        m1 = e->m1;
        m2 = e->m2;
        
        for(x=0; x<2; x++)
        {
            if(!m1->orig[x] || !m2->orig[x]) continue;
            
            rf = NO_RFLOD; //rf is bidirectional therefore should avoid calc it twice
            
            for(j=0; j<c->nind; j++)
            {
                //impute m1 from m2
                if(m1->orig[x][j] == MISSING && m2->data[x][j] != MISSING)
                {
                    if(rf == NO_RFLOD)
                    {
                        rf = impute_est_rf(c,m1,m2,x);
                        if(rf == NO_RFLOD) break;      //no usable info
                    }
                    
                    append_knn(c,&(m1->miss[x][j]),m2->data[x][j],rf);
                }

                //impute m2 from m1
                if(m2->orig[x][j] == MISSING && m1->data[x][j] != MISSING)
                {
                    if(rf == NO_RFLOD)
                    {
                        rf = impute_est_rf(c,m1,m2,x);
                        if(rf == NO_RFLOD) break;      //no usable info
                    }
                    
                    append_knn(c,&(m2->miss[x][j]),m1->data[x][j],rf);
                }
            }
        }
    }
    
    //assign values to missing data
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        
        for(x=0; x<2; x++)
        {
            if(!m->orig[x]) continue;
            
            for(j=0; j<c->nind; j++)
            {
                if(m->orig[x][j] != MISSING) continue;
                
                //DEBUG
                //printf("name=%s x=%u j=%u %u\n",m->name,x,j,m->miss[x][j].n);
                
                if(m->miss[x][j].n > 0)
                {
                    //find the average neighbouring value
                    dval = 0.0;
                    for(k=0; k<m->miss[x][j].n; k++)
                    {
                        dval += (double)m->miss[x][j].val[k];
                        //printf(" %u",m->miss[x][j].val[k]);
                    }
                    dval /= m->miss[x][j].n;
                }
                else
                {
                    //no neighbours available, pick randomly
                    dval = drand48();
                }

                //printf(" %f\n",dval);
                
                if(dval > 0.5) m->data[x][j] = 1;
                else           m->data[x][j] = 0;
                
                //infer the original, unphased value
                m->orig[x][j] = XOR(m->data[x][j],m->phase[x]);
            }
        }
    }
}

/*
allocate data structures for imputing missing values
*/
void impute_alloc(struct conf*c,unsigned nmark,struct marker**marray)
{
    unsigned i,j,x;
    struct marker*m=NULL;
    
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        
        for(x=0; x<2; x++)
        {
            if(!m->orig[x]) continue;
            
            assert(m->miss[x] = calloc(c->nind,sizeof(struct missing)));
            
            for(j=0; j<c->nind; j++)
            {
                if(m->orig[x][j] != MISSING) continue;
                
                assert(m->miss[x][j].val = calloc(c->grp_knn+1,sizeof(VARTYPE)));
                assert(m->miss[x][j].rf = calloc(c->grp_knn+1,sizeof(double)));
            }
        }
    }
}

void append_knn(struct conf*c,struct missing*z,VARTYPE val,double rf)
{
    unsigned i;
    VARTYPE vtmp;
    double dtmp;
    
    //append value to end of list
    z->val[z->n] = val;
    z->rf[z->n] = rf;
    
    //bubble the value up until sorted by rf value
    for(i=z->n; i>0; i--)
    {
        if(z->rf[i] >= z->rf[i-1]) break; //correct position found
        SWAP(z->rf[i],z->rf[i-1],dtmp);
        SWAP(z->val[i],z->val[i-1],vtmp);
    }
    
    //retain at most grp_knn items
    if(z->n < c->grp_knn) z->n += 1;
}

double impute_est_rf(struct conf*c,struct marker*m1,struct marker*m2,unsigned x)
{
    unsigned R,N;
    
    calc_RN_simple(c,m1,m2,x,&R,&N);
    
    if(N == 0) return NO_RFLOD; //no usable information between m1 and m2
    
    //estimate rf assuming missing values are different with prob 0.5
    //to avoid underestimating the distance
    return ((double)R + 0.5 * (c->nind - N)) / c->nind;
}

/*
update m->data and bit strings to reflect marker phases
*/
void update_data(struct conf*c,unsigned nmark,struct marker**marray)
{
    struct marker*m=NULL;
    unsigned i,j,x;
    
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        
        for(j=0; j<c->nind; j++)
        {
            if(m->type == HKTYPE)
            {
                //treat hk calls as missing
                if(m->code[j] == HK_CALL)
                {
                    m->data[0][j] = MISSING;
                    m->data[1][j] = MISSING;
                    continue;
                }
            }
            
            for(x=0; x<2; x++)
            {
                if(!m->orig[x]) continue;

                if(m->orig[x][j] == MISSING) m->data[x][j] = MISSING;
                else                         m->data[x][j] = XOR(m->orig[x][j],m->phase[x]);
            }
        }
    }
    
    compress_to_bitstrings(c,nmark,marray);
}

//append new edge to array, expanding first if required
void add_edge2(struct earray*e,struct marker*m1,struct marker*m2,double lod,double rf,unsigned cxr_flag,double cm,unsigned nonhk)
{
    struct edge*p=NULL;
    
    //expand the array if required
    if(e->nedges == e->nedgemax)
    {
        if(e->nedgemax == 0) e->nedgemax = 500;
        else                 e->nedgemax *= 2;
        assert(e->array = realloc(e->array,e->nedgemax*sizeof(struct edge*)));
    }
    
    assert(p = calloc(1,sizeof(struct edge)));
    e->array[e->nedges] = p;
    e->nedges += 1;
    
    p->lod = lod;
    p->rf = rf;
    p->cxr_flag = cxr_flag;
    p->m1 = m1;
    p->m2 = m2;
    p->cm = cm;
    p->nonhk = nonhk;
}

void add_edge(struct conf*c,struct marker*m1,struct marker*m2,double lod,double rf,unsigned cxr_flag,double cm,unsigned nonhk)
{
    struct edge*p=NULL;
    
    //expand the array if required
    if(c->nedge == c->nedgemax)
    {
        c->nedgemax *= 2;
        assert(c->elist = realloc(c->elist,c->nedgemax*sizeof(struct edge*)));
    }
    
    assert(p = calloc(1,sizeof(struct edge)));
    c->elist[c->nedge] = p;
    c->nedge += 1;
    
    p->lod = lod;
    p->rf = rf;
    p->cxr_flag = cxr_flag;
    p->m1 = m1;
    p->m2 = m2;
    p->cm = cm;
    p->nonhk = nonhk;
}

/*
calculate the two-point rf and lod between two markers for the given parental information only
x=0 => maternal information only
x=1 => paternal information only
the following comparisons are supported:
lm - lm
lm - hk
np - np
np - hk

calculate rf assuming coupling phase even though m->data contains unphased information
later on repulsion phase rf will be converted to the correct value
*/
void calc_rflod_simple(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,double*_lod,double*_rf)
{
    unsigned R,S,N;
    double r,s,lod;
    
    //count number of recombinants and total non-missing genotype pairs
    calc_RN_simple(c,m1,m2,x,&R,&N);
    
    if(N == 0)
    {
        //rf and lod are undefined
        *_rf = NO_RFLOD;
        *_lod = NO_RFLOD;
        return;
    }
    
    r = (double)R / N;
    
    //calculate linkage LOD
    s = 1.0 - r;
    S = N - R;
    
    lod = 0.0;
    if(s > 0.0) lod += S * LOG10(2.0*s);
    if(r > 0.0) lod += R * LOG10(2.0*r);

    *_rf = r;
    *_lod = lod;
}

void calc_rflod_simple2(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,unsigned y,double*_lod,double*_rf)
{
    unsigned R,S,N;
    double r,s,lod;
    
    //count number of recombinants and total non-missing genotype pairs
    calc_RN_simple2(c,m1,m2,x,y,&R,&N);
    
    if(N == 0)
    {
        //rf and lod are undefined
        *_rf = NO_RFLOD;
        *_lod = NO_RFLOD;
        return;
    }
    
    r = (double)R / N;
    
    //calculate linkage LOD
    s = 1.0 - r;
    S = N - R;
    
    lod = 0.0;
    if(s > 0.0) lod += S * LOG10(2.0*s);
    if(r > 0.0) lod += R * LOG10(2.0*r);

    *_rf = r;
    *_lod = lod;
}

/*
calculate rf and LOD using 2pt methods from Maliepaard
this method implicitly deduces phase as far as possible
and should not be used between two markers where the phasing is already known
with possibly higher certainty through indirect means
*/
void calc_rflod_hk(struct conf*c,VARTYPE*m1,VARTYPE*m2,double*_lod,double*_rf,unsigned*_cxr_flag)
{
    unsigned i,j,N;
    unsigned n[10] = {0,0,0,0,0,0,0,0,0,0};
    double r,s,val,sum1,sum2,sum3;
    double lod_cxr,lod_cxc,rf_cxr,rf_cxc;
    
    //count combinations of marker calls in each catergory
    //n[1] ...n[9] correspond to n1...n9 in Table 2.3 Maliepaard et al. (1997)
    //n[0] is unused
    N = 0;
    for(i=0; i<c->nind; i++)
    {
        if(m1[i] == MISSING || m2[i] == MISSING) continue;
        N += 1;
        j = 3 * m1[i] + m2[i] + 1;
        n[j] += 1;
    }
    
    if(N == 0)
    {
        //rf and lod are undefined
        *_rf = NO_RFLOD;
        *_lod = NO_RFLOD;
        return;
    }
    
    //calc ML estimate of rf assuming cxr or rxc phasing
    //see Maliepaard et al. (1997) Table 2.3, case No. 7
    
    sum1 = n[1] + n[3] + n[5] + n[7] + n[9]; //n[1] ...n[9] correspond to n1...n9 in Table 2.3
    sum2 = n[2] + n[4] + n[6] + n[8];
    val = 0.25 - sum1 / (2.0 * (double)N);   //val e [-1/4, 1/4]
    
    lod_cxr = NO_RFLOD;
    rf_cxr = NO_RFLOD;
    
    if(val >= 0.0)
    {
        //rf_cxr is real
        rf_cxr = 0.5 - sqrt(val);      //r e [0,1/2]
        if(rf_cxr < 0.0) rf_cxr = 0.0; //incase rounding errors make rf less than zero
        
        s = 1.0 - rf_cxr;
        lod_cxr = 0.0;
        val = 4.0 * rf_cxr * s;                     //e [0,1]
        if(val > 0.0) lod_cxr += sum1 * LOG10(val); //val==0 only if sum1==0 therefore lod+=0 in this case
        val = 2.0 - 4.0 * rf_cxr * s;               //e[1,2]
        assert(val > 0.0);
        lod_cxr += sum2 * LOG10(val);
    }
    //else rf_cxr is imaginary
    
    //calc ML estimate assuming cxc phasing
    //using EM
    lod_cxc = NO_RFLOD;
    rf_cxc = 0.25;
    s = 1.0 - rf_cxc;

    sum3 = sum2 + 2.0 * ((double)n[3] + n[7]);
    
    for(i=0; i<c->grp_em_maxit; i++)
    {
        r = (sum3 + 2.0*(double)n[5]*rf_cxc*rf_cxc
                    / (1.0 - 2.0*rf_cxc*s))          // >= 0.5
            / (2.0 * (double)N);
        
        val = fabs(r - rf_cxc);
        rf_cxc = r;
        s = 1.0 - rf_cxc;
        
        if(val < c->grp_em_tol) break;
    }
    
    if(i >= c->grp_em_maxit || rf_cxc < -0.0001 || rf_cxc > 1.0001)
    {
        //rf_cxc failed to converge on a sensible value
        //cannot be cxc linkage
        *_rf = rf_cxr;
        *_lod = lod_cxr;
        *_cxr_flag = 1;
        return;
    }
    
    if(rf_cxc < 0.0) rf_cxc = 0.0;
    else if(rf_cxc > 1.0) rf_cxc = 1.0;
    
    s = 1.0 - rf_cxc;
    
    lod_cxc = 0.0;
    val = 2.0 * s; //e [0,1]
                                  //non recomb counts
    if(val > 0.0) lod_cxc += 2.0*((double)n[1] + n[9]) * LOG10(val);
    
    val = 4.0 * rf_cxc * s; //e [0,1]
    
                             //1 recomb counts
    if(val > 0.0) lod_cxc += sum2 * LOG10(val);
    
                                     //2 recomb counts
    if(rf_cxc > 0.0) lod_cxc += 2.0*((double)n[3] + n[7]) * LOG10(2.0 * rf_cxc);
    
    val = 2.0 - 4.0 * rf_cxc * s; //e [1,2]
    assert(val > 0.0);
                       //two or zero recomb count
    lod_cxc += (double)n[5] * LOG10(val);
    
    if(lod_cxc > lod_cxr)
    {
        //treat as cxc / rxr phase
        *_lod = lod_cxc;
        *_rf = rf_cxc;
        *_cxr_flag = 0;
    }
    else
    {
        //treat as cxr / rxc phase
        *_lod = lod_cxr;
        *_rf = rf_cxr;
        *_cxr_flag = 1;
    }
}

//remove edges pointing to redundant markers
//remove redundant markers and output their names, plus the group of redundant markers they belong to
//ie output the name of the remaining marker which represents them
void remove_redundant_markers(struct conf*c,struct lg*p,struct earray*ea)
{
    struct edge*e=NULL;
    struct marker*m=NULL;
    struct marker*parent=NULL;
    unsigned i;
    FILE*f=NULL;
    
    //remove edges connected to redundant markers
    i = 0;
    while(i < ea->nedges)
    {
        e = ea->array[i];
        
        if(e->m1->uf_parent == NULL && e->m2->uf_parent == NULL)
        {
            //retain this edge
            i += 1;
            continue;
        }
        
        //replace with last edge in the list
        free(e);
        ea->array[i] = ea->array[ea->nedges-1];
        ea->nedges -= 1;
    }
    
    //could realloc ea->array here

    //file to receive names of markers that were removed 
    if(c->redun != NULL) assert(f = fopen(c->redun,"wb"));

    //remove redundant markers
    i = 0;
    while(i<p->nmarkers)
    {
        m = p->array[i];
        
        if(m->uf_parent == NULL)
        {
            i += 1;
            continue; //retain marker
        }
        
        //find the marker which will represent the removed marker
        parent = m->uf_parent;
        while(parent->uf_parent) parent = parent->uf_parent;
        
        //record redundant marker name and the name of the remaining marker
        if(f) fprintf(f,"%s %s\n",m->name,parent->name);

        free(m);
        p->array[i] = p->array[p->nmarkers-1];
        p->nmarkers -= 1;
    }

    //could realloc p->array here
    
    if(f) fclose(f);
}

//return whether p1 or p2 or either can be considered redundant wrt the other
//1 => only 1 is redundant
//2 => only 2 is redundant
//3 => either is redundant with respect to the other
unsigned find_redundant(struct conf*c,VARTYPE*p1,VARTYPE*p2,double rf)
{
    unsigned i,keep1=0,keep2=0;
    
    if(rf < 0.5)
    {
        //expecting all calls to be equal
        for(i=0; i<c->nind; i++)
        {
            if(p1[i] == p2[i])
            {
                //equal or both missing
                continue;
            }
            else if(p1[i] == MISSING)
            {
                //m2 not redundant
                if(keep1) return 0; //neither is redundant
                keep2 = 1;
            }
            else if(p2[i] == MISSING)
            {
                //m1 not redundant
                if(keep2) return 0; //neither is redundant
                keep1 = 1;
            }
            else
            {
                //not equal but neither missing
                //neither marker is redundant
                return 0;
            }
        }
    }
    else
    {
        //expecting all calls to be different
        for(i=0; i<c->nind; i++)
        {
            if(p1[i] == MISSING && p2[i] == MISSING)
            {
                //both missing
                continue;
            }
            else if(p1[i] == MISSING)
            {
                //m2 not redundant
                if(keep1) return 0; //neither is redundant
                keep2 = 1;
            }
            else if(p2[i] == MISSING)
            {
                //m1 not redundant
                if(keep2) return 0; //neither is redundant
                keep1 = 1;
            }
            else if(p1[i] == p2[i])
            {
                //equal so neither marker is redundant
                return 0;
            }
        }
    }
    
    if(keep1 == 1)
    {
        assert(keep2 == 0);
        return 2; //2 is redundant
    }
    else if(keep2 == 1)
    {
        return 1; //1 is redundant
    }
    
    assert(keep1 == 0 && keep2 == 0);
    
    //markers contain equivalent information, either can be treated as redundant
    return 3;
}

void identify_redundant_markers(struct conf*c,struct marker*m1,struct marker*m2,double rf,unsigned cxr_flag)
{
    VARTYPE*p1=NULL;
    VARTYPE*p2=NULL;
    unsigned result,result2;
    
    //HK vs HK
    if(m1->type == HKTYPE && m2->type == HKTYPE)
    {
        if(cxr_flag) return; //cannot compare directly
        
        //compare both pairs of data arrays
        result  = find_redundant(c,m1->data[0],m2->data[0],rf);
        result2 = find_redundant(c,m1->data[1],m2->data[1],rf);
        
        if(result == 0 || result2 == 0) return; //neither marker is redundant
        
        if((result & 0x2) && (result2 & 0x2))
        {
            m2->uf_parent = m1; //marker 2 is redundant
        }
        else if((result & 0x1) && (result2 & 0x1))
        {
            m1->uf_parent = m2; //marker 1 is redundant
        }
        
        return;
    }
    
    //HK vs nonHK
    if(m1->type == HKTYPE || m2->type == HKTYPE)
    {
        return;
    }
    //LM vs LM
    else if(m1->type == LMTYPE && m2->type == LMTYPE)
    {
        p1 = m1->data[0];
        p2 = m2->data[0];
    }
    //NP vs NP
    else if(m1->type == NPTYPE && m2->type == NPTYPE)
    {
        p1 = m1->data[1];
        p2 = m2->data[1];
    }
    //LM vs NP
    else if(m1->type == LMTYPE && m2->type == NPTYPE)
    {
        p1 = m1->data[0];
        p2 = m2->data[1];
    }
    //NP vs LM
    else
    {
        assert(m1->type == NPTYPE && m2->type == LMTYPE);
        p1 = m1->data[1];
        p2 = m2->data[0];
    }

    result = find_redundant(c,p1,p2,rf);
    
    if(result & 0x2)      m2->uf_parent = m1; //marker 2 (or either) redundant
    else if(result & 0x1) m1->uf_parent = m2; //marker 1 redundant
}

/*
build a list of all lod values above the threshold
by scanning all-vs-all markers
*/
void build_elist(struct conf*c,struct lg*p,struct earray*e)
{
    unsigned i,j;
    double lod,rf;
    unsigned cxr_flag,nonhk;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    
    //if marker is flagged as redundant set this pointer to the "parent" (less redundant) marker
    for(i=0; i<p->nmarkers; i++) p->array[i]->uf_parent = NULL;
    
    for(i=0; i<p->nmarkers-1; i++)
    {
        m1 = p->array[i];
        if(m1->uf_parent) continue;
        
        for(j=i+1; j<p->nmarkers; j++)
        {
            m2 = p->array[j];
            if(m2->uf_parent) continue;
            
            lod = NO_RFLOD;
            rf = NO_RFLOD;
            cxr_flag = 0;
            
            //is either marker an hk?
            if(m1->type == HKTYPE || m2->type == HKTYPE) nonhk = 0;
            else                                         nonhk = 1;
            
            //HK vs HK marker
            if(m1->type == HKTYPE && m2->type == HKTYPE)
            {
                calc_rflod_hk(c,m1->code,m2->code,&lod,&rf,&cxr_flag);
                
                if(c->grp_ignore_cxr && cxr_flag) continue; //ignore cxr / rxc linkage
            }
            else
            {
                //LM vs LM or HK
                if(m1->data[0] && m2->data[0])
                {
                    calc_rflod_simple(c,m1,m2,0,&lod,&rf);
                }
                //NP vs NP or HK
                else if(m1->data[1] && m2->data[1])
                {
                    calc_rflod_simple(c,m1,m2,1,&lod,&rf);
                }
                //LM vs NP if matpat option is active
                else if(c->grp_matpat_lod > 0.0)
                {
                    if(m1->type == LMTYPE && m2->type == NPTYPE)
                    {
                        calc_rflod_simple2(c,m1,m2,0,1,&lod,&rf);
                    }
                    else if(m1->type == NPTYPE && m2->type == LMTYPE)
                    {
                        calc_rflod_simple2(c,m1,m2,1,0,&lod,&rf);
                    }
                    
                    //apply additional lod threshold
                    if(lod < c->grp_matpat_lod || lod == NO_RFLOD) continue;
                }
            }

            if(lod < c->grp_min_lod || lod == NO_RFLOD) continue;
            
            //check for redundant markers
            if(!cxr_flag && c->grp_redundancy_lod && lod >= c->grp_redundancy_lod && (rf < 1e-4 || rf > 1.0-1e-4))
            {
                identify_redundant_markers(c,m1,m2,rf,cxr_flag);
                
                if(m1->uf_parent) break;
                if(m2->uf_parent) continue;
            }
            
            //DEBUG
            //printf("%s %s lod= %f rf= %f cxrflag= %u\n",m1->name,m2->name,lod,rf,cxr_flag);

            add_edge2(e,m1,m2,lod,rf,cxr_flag,0.0,nonhk);
        }
    }
    
    if(c->flog) fprintf(c->flog,"#%u edges added\n",e->nedges);
}

//sort edges into ascending order by map distance
//but give first priorty to non-hk edges
int ecomp_mapdist_nonhk(const void*_p1, const void*_p2)
{
    struct edge*p1=NULL;
    struct edge*p2=NULL;
    
    p1 = *((struct edge**)_p1);
    p2 = *((struct edge**)_p2);
    
    //prioritise nonhk
    if(p1->nonhk && !p2->nonhk) return -1;
    if(!p1->nonhk && p2->nonhk) return 1;
    
    //prioritise shorter map distance
    if(p1->cm < p2->cm) return -1;
    if(p1->cm > p2->cm) return 1;
    return 0;
}

/*sort edges so that largest lod is at the top*/
void sort_elist(struct earray*e)
{
    
    qsort(e->array,e->nedges,sizeof(struct edge*),ecomp_func);

    //unsigned i;
    //for(i=0; i<c->nedge; i++) printf("%f\n",c->elist[i]->lod);
}

//find func of union-find
struct marker*find_group(struct marker*m)
{
    while(m->uf_parent != m) m = m->uf_parent;
    return m;
}

//union func of union-find
unsigned union_groups(struct marker*m1,struct marker*m2)
{
    struct marker*p1=NULL;
    struct marker*p2=NULL;
    
    p1 = find_group(m1);
    p2 = find_group(m2);
    
    if(p1 == p2) return 0;   //already in same group
    
    //merge groups
    if(p1->uf_rank < p2->uf_rank)
    {
        p1->uf_parent = p2;
        p2->uf_rank += p1->uf_rank;
        return 1; //m1's group merged into m2's group
    }
    else
    {
        p2->uf_parent = p1;
        p1->uf_rank += p2->uf_rank;
        return 2; //m2's group merged into m1's group
    }
}

/*
used by qsort to sort the list into descending order by lod
*/
int ecomp_func(const void*_p1, const void*_p2)
{
    struct edge*p1=NULL;
    struct edge*p2=NULL;
    
    p1 = *((struct edge**)_p1);
    p2 = *((struct edge**)_p2);
    
    if(p1->lod < p2->lod) return 1;
    if(p1->lod > p2->lod) return -1;
    return 0;
}

/*
used by qsort to sort the list into descending order by lod
but putting any cxr edges at the bottom
*/
int ecomp_cxr_func(const void*_p1, const void*_p2)
{
    struct edge*p1=NULL;
    struct edge*p2=NULL;
    
    p1 = *((struct edge**)_p1);
    p2 = *((struct edge**)_p2);
    
    if(p1->cxr_flag && !p2->cxr_flag) return 1;
    if(!p1->cxr_flag && p2->cxr_flag) return -1;
    
    if(p1->lod < p2->lod) return 1;
    if(p1->lod > p2->lod) return -1;
    return 0;
}

/*
form linkage groups using edges in order of decreasing lod
use all edges (including cxr/rxc edges)
no phasing is performed, just grouping
*/
void form_groups(struct conf*c,struct lg*p,struct earray*ea,struct map*mp)
{
    unsigned i;
    double min_lod_used=-1.0;
    struct edge*e=NULL;
    struct marker*m=NULL;

    //no actual need to sort edges by LOD if we will use all of them for LG formation
    //but useful to be able to report minlod used!
    //sort edges by LOD, largest LOD values go first
    qsort(ea->array,ea->nedges,sizeof(struct edge*),ecomp_func);
    
    //initialise to a disconnected forest
    mp->nlgs = p->nmarkers;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        m->uf_parent = m;
        m->uf_rank = 1;
    }
    
    //perform unions between groups until no more (lod-filtered) edges are left
    for(i=0; i<ea->nedges && mp->nlgs > 1; i++)
    {
        e = ea->array[i];
        
        if(union_groups(e->m1,e->m2))
        {
            mp->nlgs -= 1;
            min_lod_used = e->lod;
            
            //printf("union %s %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
        }
    }
    
    if(c->flog) fprintf(c->flog,"#formed %u linkage groups with a min lod of %f\n",mp->nlgs,min_lod_used);
 
    split_markers(p,mp);
    split_edges(ea,mp);
}

/*
build LOD-MST per LG
use this to phase all markers
deal with maternal and paternal phases separately
x=0 => maternal
x=1 => paternal
cxr edges, if present, should be sorted to be end of the edge list
to avoid using them if possible
if forced to use them, guess coupling phase for maternal and repulsion phase for paternal
and warn in the logs
*/
void phase_markers(struct conf*c,struct lg*p,struct earray*ea,unsigned x)
{
    struct marker*m=NULL;
    struct marker*m_start=NULL;
    struct edge*e=NULL;
    struct edgelist*p1=NULL;
    struct edgelist*p2=NULL;
    unsigned i,ntrees;
    unsigned nepool,nepoolmax;
    struct edgelist*epool=NULL;
    char *lab[] = {"mat","pat"};
    double minlod;
    
    //sort edges by decreasing lod with cxr edges below noncxr
    qsort(ea->array,ea->nedges,sizeof(struct edge*),ecomp_cxr_func);
    
    //printf("phase_markers x=%u\n",x);
    /*for(i=0; i<c->lg_nedges[lg]; i++)
    {
        e = c->lg_edges[lg][i];
        printf("%s %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
    }*/

    //initialise to disconnected forest
    ntrees = 0;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        
        //each marker begins in its own group with no attached edges
        m->uf_parent = m;
        m->uf_rank = 1;
        m->adj_list = NULL;
        m->dfs_marked = 0;
        
        if(m->data[x])
        {
            ntrees += 1;
            if(m_start == NULL) m_start = m; //a suitable marker for start of dfs
        }
    }
    
    //check we have some markers to phase
    if(ntrees < 2)
    {
        if(c->flog) fprintf(c->flog,"#phasing lg %s(%s) found %d applicable markers, no phasing required\n",
                            p->name,lab[x],ntrees);
        return;
    }
    
    //alloc edgelists
    //max MST edges required is approx 2*lg_nmarkers[lg] because
    //each edge appears on both marker's adjacency lists
    nepool = 0;
    nepoolmax = 2 * p->nmarkers;
    assert(epool = calloc(nepoolmax,sizeof(struct edgelist)));
    
    //printf("initial trees %u\n",ntrees);

    /*
    union-find into an MST ignoring cxr linkage between hk's
    build MST with Kruskal's algorithm:
    perform unions by decreasing edge lod until one tree results
    or until no more edges (ie phasing fails to complete)
    store MST using adjacency lists (the tree is very sparse)
    */
    minlod = -1.0;
    for(i=0; i<ea->nedges && ntrees>1; i++)
    {
        e = ea->array[i];
        
        //ignore if edge involves information from the wrong parent
        if(e->m1->data[x] == NULL || e->m2->data[x] == NULL) continue;
        
        
        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
        
        if(union_groups(e->m1,e->m2) == 0) continue;
        
        minlod = e->lod;

        ntrees -= 1;
        
        //ignore cxr / rxc hk-hk linkage
        //since this provides incomplete phasing information
        if(e->cxr_flag && c->flog) fprintf(c->flog,"#phasing lg %s(%s) warning: using cxr linkage during phasing\n",p->name,lab[x]);

        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);

        /*
        MST: link the two markers
        */
        
        //store the edge in both marker's adjacency lists
        p1 = &epool[nepool++];
        p2 = &epool[nepool++];
        assert(nepool <= nepoolmax);
        
        p1->e = e;
        p2->e = e;
        p1->next = NULL;
        p2->next = NULL;

        append_edge(&e->m1->adj_list,p1);
        append_edge(&e->m2->adj_list,p2);
        
        //printf("%s => %s lod=%f rf=%f\n",e->m1->name,e->m2->name,e->lod,e->rf);
    }
    
    if(c->flog) fprintf(c->flog,"#phasing lg %s(%s) with a min lod of %.4lf\n",p->name,lab[x],minlod);

    //abort phasing if failed to resolve into a single group
    if(ntrees > 1)
    {
        if(c->flog) fprintf(c->flog,"#phasing lg %s(%s) failed: still split into %u subgroups\n",p->name,lab[x],ntrees);
        return;
    }
    
    /*for(i=0; i<c->lg_nmarkers[lg]; i++)
    {
        p1 = c->lg_markers[lg][i]->adj_list;
        printf("marker %s\n",c->lg_markers[lg][i]->name);
        while(p1)
        {
            printf("%s\n",other(p1,c->lg_markers[lg][i])->name);
            p1 = p1->next;
        }
    }*/

    //DEBUG
    //printf("lg_nmarkers=%u\n",c->lg_nmarkers[lg]);

    /*
    do a depth-first search
    setting phase values
    */
    assert(m_start);
    
    dfs_phase(c,m_start,0,x);
    
    free(epool);
}

/*
depth-first search used to phase markers
*/
void dfs_phase(struct conf*c,struct marker*m,unsigned phase,unsigned x)
{
    struct edgelist*p=NULL;
    struct marker*m2=NULL;
    
    //mark this node as visited
    assert(!m->dfs_marked);
    m->dfs_marked = 1;
    m->phase[x] = phase;
    
    //visit all unmarked adjacent nodes
    p = m->adj_list;
    
    while(p)
    {
        m2 = other(p,m);
        
        if(!m2->dfs_marked)
        {
            if(p->e->cxr_flag)
            {
                //it could be cxr or rxc, guess it is cxr
                if(x == 0) dfs_phase(c,m2,phase,x);  //coupling
                else       dfs_phase(c,m2,!phase,x); //repulsion
            }
            else
            {
                //use rf to deduce coupling or repulsion phase
                if(p->e->rf < 0.5) dfs_phase(c,m2,phase,x); //coupling
                else               dfs_phase(c,m2,!phase,x); //repulsion
            }
        }
        
        p = p->next;
    }
}

//calc map distance associated with each edge then sort by map distance
//here we assume phase was worked out using the best available information
//which could be an indirect route ie not be the direct marker-marker edge itself
//therefore we look at m->phase[] not the info in the edge itself
//edges are sorted to give priority to nonhk markers
void distance_and_sort(struct conf*c,struct earray*ea)
{
    struct edge*e=NULL;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    double rf;
    unsigned i;
    
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];
        m1 = e->m1;
        m2 = e->m2;
        
        rf = NO_RFLOD;
        
        //determine the phase relationship between the two markers
        if(m1->type == HKTYPE && m2->type == HKTYPE) //HK vs HK
        {
            if(m1->phase[0] != m2->phase[0] && m1->phase[1] != m2->phase[1]) rf = 1.0 - e->rf; //rxr
            else                                                             rf = e->rf;       //cxc,cxr or rxc
        }
        else if(m1->data[0] && m2->data[0]) //LM vs LM or HK
        {
            if(m1->phase[0] == m2->phase[0]) rf = e->rf;       //coupling
            else                             rf = 1.0 - e->rf; //repulsion
        }
        else if(m1->data[1] && m2->data[1]) //NP vs NP or HK
        {
            if(m1->phase[1] == m2->phase[1]) rf = e->rf;       //coupling
            else                             rf = 1.0 - e->rf; //repulsion
        }
        
        assert(rf != NO_RFLOD);
        
        if(rf < 0.0) rf = 0.0;
        else if(rf > MAX_RF) rf = MAX_RF;
        
        e->cm = c->map_func(rf);
        
        //printf("%s %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
    }

    //sort edges into ascending cM
    qsort(ea->array,ea->nedges,sizeof(struct edge*),ecomp_mapdist_nonhk);
}

/*
build centimorgan-minimising MST per LG including cxr / rxc linkage
deal with maternal and paternal information separately
x=0 => maternal
x=1 => paternal
*/
void order_markers2(struct conf*c,struct lg*p,struct earray*ea,unsigned x)
{
    struct marker*m=NULL;
    //struct marker*mtmp=NULL;
    struct marker*m_start=NULL;
    struct marker*m_end=NULL;
    struct edge*e=NULL;
    struct edgelist*p1=NULL;
    struct edgelist*p2=NULL;
    unsigned i,ntrees;
    double dist;
    char *lab[] = {"mat","pat"};
    unsigned nepool,nepoolmax;
    struct edgelist*epool=NULL;
    
    //printf("phase_markers x=%u\n",x);
    /*for(i=0; i<c->lg_nedges[lg]; i++)
    {
        e = c->lg_edges[lg][i];
        printf("%s %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
    }*/

    //initialise to disconnected forest
    ntrees = 0;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        
        //each marker begins in its own group with no attached edges
        m->uf_parent = m;
        m->uf_rank = 1;
        m->adj_list = NULL;
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
        
        if(m->data[x])
        {
            ntrees += 1;
            if(m_start == NULL) m_start = m; //a suitable marker for start of dfs
        }
    }
    
    if(ntrees == 0)
    {
        if(c->flog) fprintf(c->flog,"lg %s(%s) no markers to order\n",p->name,lab[x]);
        return; //no markers to order
    }
    
    //DEBUG
    //printf("initial trees= %u\n",ntrees);
    
    //alloc more edgelists if required
    //max MST edges required is approx 2*lg_nmarkers[lg] because
    //each edge appears on both marker's adjacency lists
    nepool = 0;
    nepoolmax = 2 * p->nmarkers;
    assert(epool = calloc(nepoolmax,sizeof(struct edgelist)));
    
    //printf("initial trees %u\n",ntrees);

    //union-find into an MST including cxr linkage
    //build MST with Kruskal's algorithm:
    //perform unions by increasing edge cM (map distance) until one tree results
    //or until no more edges
    //store MST using adjacency lists
    for(i=0; i<ea->nedges && ntrees>1; i++)
    {
        e = ea->array[i];
        
        //ignore if edge involves information from the wrong parent
        if(e->m1->data[x] == NULL || e->m2->data[x] == NULL) continue;
        
        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
        
        //see if the edge joins two separate trees into one
        if(union_groups(e->m1,e->m2) == 0) continue;
        
        ntrees -= 1;
        
        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);

        //MST: link the two markers
        
        //store the edge in both marker's adjacency lists
        p1 = &epool[nepool++];
        p2 = &epool[nepool++];
        assert(nepool <= nepoolmax);
        
        p1->e = e;
        p2->e = e;
        p1->next = NULL;
        p2->next = NULL;

        append_edge(&e->m1->adj_list,p1);
        append_edge(&e->m2->adj_list,p2);
        
        //DEBUG
        /*printf("order_marker %s(type=%u,lg=%u,rank=%u) => %s(%u,%u,rank=%u) lod=%f rf=%f ntrees=%u %u/%u\n",
               e->m1->name,e->m1->type,e->m1->lg,find_group(e->m1)->uf_rank,
               e->m2->name,e->m2->type,e->m2->lg,find_group(e->m1)->uf_rank,
               e->lod,e->rf,ntrees,i,nedge);*/
    }
    
    /*if(ntrees != 1)
    {
        //DEBUG
        struct marker*mtmp;
        for(i=0; i<nmark; i++)
        {
            m = marray[i];
            mtmp = find_group(m);
            printf("%s %p treesize=%u\n",m->name,mtmp,mtmp->uf_rank);
        }
        printf("ntrees=%u\n",ntrees);
    }*/
    
    if(ntrees > 1)
    {
        /*for(i=0; i<p->nmarkers; i++)
        {
            m = p->array[i];
            m->pos[x] = NO_POSN;           //should already be set to this value
        }*/
        
        if(c->flog) fprintf(c->flog,"#lg %s(%s): backbone resolved into %u subgroups\n",p->name,lab[x],ntrees);
        
        return;
    }
    
    
    /*for(i=0; i<c->lg_nmarkers[lg]; i++)
    {
        p1 = c->lg_markers[lg][i]->adj_list;
        printf("marker %s\n",c->lg_markers[lg][i]->name);
        while(p1)
        {
            printf("%s\n",other(p1,c->lg_markers[lg][i])->name);
            p1 = p1->next;
        }
    }*/

    //prepare for dfs
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
    }

    //do first depth-first search
    //find the furthest vertex from the source
    assert(m_start);
    c->dfs_maxdist = -1.0;
    c->dfs_maxmarker = NULL;
    dfs_order(c,m_start,0.0);
    
    //prepare for dfs
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
    }

    //printf("maxdist=%f\n",c->dfs_maxdist);

    //do second depth-first search
    //find the furthest vertex from the new source
    m_start = c->dfs_maxmarker;
    c->dfs_maxdist = -1.0;
    dfs_order(c,m_start,0.0);
    m_end = c->dfs_maxmarker;
    
    //printf("maxdist=%f\n",c->dfs_maxdist);

    //assign map positions along the longest path
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        m->dfs_marked = 0;
        //m->pos[x] = NO_POSN;           //no map position defined yet
    }
    
    //trace path back from last marker
    unsigned count=0;
    dist = 0.0;
    m = m_end;
    
    while(1)
    {
        m->pos[x] = dist;
        m->dfs_marked = 1; //mark as already visited
        count += 1;        //count markers in the longest path
        
        //output just the backbone positions
        //printf("%s %u %f\n",m->name,x,m->pos[x]);
        
        if(m->dfs_parent == NULL) break;
        dist += m->dfs_parent->e->cm;
        m = other(m->dfs_parent,m);
    }
    
    if(c->flog) fprintf(c->flog,"#lg %s(%s): %u markers on backbone\n",p->name,lab[x],count);
    
    //for any markers not on the longest path
    //assign position of nearest marker that is on the path
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        if(m->dfs_marked) dfs_assign(m,m->pos[x],x);
    }
    
    /*for(i=0; i<c->lg_nmarkers[lg]; i++)
    {
        m = c->lg_markers[lg][i];
        printf("%s %u %f\n",m->name,x,m->pos[x]);
    }*/
    
    free(epool);
}

/*
build centimorgan-minimising MST per LG including cxr / rxc linkage
deal with maternal and paternal information separately
x=0 => maternal
x=1 => paternal
*/
void order_markers(struct conf*c,unsigned nmark,struct marker**marray,unsigned nedge,struct edge**elist,unsigned x)
{
    struct marker*m=NULL;
    //struct marker*mtmp=NULL;
    struct marker*m_start=NULL;
    struct marker*m_end=NULL;
    struct edge*e=NULL;
    struct edgelist*p1=NULL;
    struct edgelist*p2=NULL;
    unsigned i,ntrees,ret;
    double dist;
    
    //printf("phase_markers x=%u\n",x);
    /*for(i=0; i<c->lg_nedges[lg]; i++)
    {
        e = c->lg_edges[lg][i];
        printf("%s %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
    }*/

    //initialise to disconnected forest
    ntrees = 0;
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        
        //each marker begins in its own group with no attached edges
        m->uf_parent = m;
        m->uf_rank = 1;
        m->adj_list = NULL;
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
        
        if(m->data[x])
        {
            ntrees += 1;
            if(m_start == NULL) m_start = m; //a suitable marker for start of dfs
        }
    }
    
    if(ntrees == 0) return; //no markers to order
    
    //DEBUG
    //printf("initial trees= %u\n",ntrees);
    
    //alloc more edgelists if required
    //max MST edges required is approx 2*lg_nmarkers[lg] because
    //each edge appears on both marker's adjacency lists
    c->nepool = 0;
    if(c->nepoolmax < 2 * nmark)
    {
        assert(c->epool = realloc(c->epool,2*nmark*sizeof(struct edgelist)));
        c->nepoolmax = 2 * nmark;
    }
    
    //printf("initial trees %u\n",ntrees);

    //union-find into an MST including cxr linkage
    //build MST with Kruskal's algorithm:
    //perform unions by increasing edge cM (map distance) until one tree results
    //or until no more edges
    //store MST using adjacency lists
    for(i=0; i<nedge && ntrees>1; i++)
    {
        e = elist[i];
        
        //ignore if edge involves information from the wrong parent
        if(e->m1->data[x] == NULL || e->m2->data[x] == NULL) continue;
        
        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);
        
        //see if the edge joins two separate trees into one
        ret = union_groups(e->m1,e->m2);
        
        if(ret == 0) continue; //no union
        
        //printf("edge: %s => %s lod=%f rf=%f cxr=%u\n",e->m1->name,e->m2->name,e->lod,e->rf,e->cxr_flag);

        //MST: link the two markers
        
        //store the edge in both marker's adjacency lists
        p1 = &c->epool[c->nepool++];
        p2 = &c->epool[c->nepool++];
        assert(c->nepool <= c->nepoolmax);
        
        p1->e = e;
        p2->e = e;
        p1->next = NULL;
        p2->next = NULL;

        append_edge(&e->m1->adj_list,p1);
        append_edge(&e->m2->adj_list,p2);
        
        
        ntrees -= 1;
        
        //DEBUG
        /*printf("order_marker %s(type=%u,lg=%u,rank=%u) => %s(%u,%u,rank=%u) lod=%f rf=%f ntrees=%u %u/%u\n",
               e->m1->name,e->m1->type,e->m1->lg,find_group(e->m1)->uf_rank,
               e->m2->name,e->m2->type,e->m2->lg,find_group(e->m1)->uf_rank,
               e->lod,e->rf,ntrees,i,nedge);*/
    }
    
    /*if(ntrees != 1)
    {
        //DEBUG
        struct marker*mtmp;
        for(i=0; i<nmark; i++)
        {
            m = marray[i];
            mtmp = find_group(m);
            printf("%s %p treesize=%u\n",m->name,mtmp,mtmp->uf_rank);
        }
        printf("ntrees=%u\n",ntrees);
    }*/
    
    if(ntrees > 1)
    {
        for(i=0; i<nmark; i++)
        {
            m = marray[i];
            m->pos[x] = NO_POSN;           //no map position defined
        }
        
        if(c->flog)
        {
            if(x == 0) fprintf(c->flog,"#failed to order maternal map backbone\n");
            else       fprintf(c->flog,"#failed to order paternal map backbone\n");
        }
        
        return;
    }
    
    
    /*for(i=0; i<c->lg_nmarkers[lg]; i++)
    {
        p1 = c->lg_markers[lg][i]->adj_list;
        printf("marker %s\n",c->lg_markers[lg][i]->name);
        while(p1)
        {
            printf("%s\n",other(p1,c->lg_markers[lg][i])->name);
            p1 = p1->next;
        }
    }*/

    //prepare for dfs
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
    }

    //do first depth-first search
    //find the furthest vertex from the source
    assert(m_start);
    c->dfs_maxdist = -1.0;
    c->dfs_maxmarker = NULL;
    dfs_order(c,m_start,0.0);
    
    //prepare for dfs
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        m->dfs_marked = 0;
        m->dfs_parent = NULL;
    }

    //printf("maxdist=%f\n",c->dfs_maxdist);

    //do second depth-first search
    //find the furthest vertex from the new source
    m_start = c->dfs_maxmarker;
    c->dfs_maxdist = -1.0;
    dfs_order(c,m_start,0.0);
    m_end = c->dfs_maxmarker;
    
    //printf("maxdist=%f\n",c->dfs_maxdist);

    //assign map positions along the longest path
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        m->dfs_marked = 0;
        m->pos[x] = NO_POSN;           //no map position defined yet
    }
    
    //trace path back from last marker
    unsigned count=0;
    dist = 0.0;
    m = m_end;
    while(1)
    {
        m->pos[x] = dist;
        m->dfs_marked = 1; //mark as already visited
        count += 1;        //count markers in the longest path
        
        //output just the backbone positions
        //printf("%s %u %f\n",m->name,x,m->pos[x]);
        
        if(m->dfs_parent == NULL) break;
        dist += m->dfs_parent->e->cm;
        m = other(m->dfs_parent,m);
    }
    
    if(c->flog)
    {
        if(x == 0) fprintf(c->flog,"#%u markers on maternal map backbone\n",count);
        else       fprintf(c->flog,"#%u markers on paternal map backbone\n",count);
    }
    
    //for any markers not on the longest path
    //assign position of nearest marker that is on the path
    for(i=0; i<nmark; i++)
    {
        m = marray[i];
        if(m->dfs_marked) dfs_assign(m,m->pos[x],x);
    }
    
    /*for(i=0; i<c->lg_nmarkers[lg]; i++)
    {
        m = c->lg_markers[lg][i];
        printf("%s %u %f\n",m->name,x,m->pos[x]);
    }*/
}

//assign position of nearest positioned marker to unpositioned markers
void dfs_assign(struct marker*m,double pos,unsigned x)
{
    struct edgelist*p=NULL;
    struct marker*m2=NULL;
    
    //mark this node as visited, assign position
    m->dfs_marked = 1;
    m->pos[x] = pos;
    
    //visit all unmarked adjacent nodes
    p = m->adj_list;
    
    while(p)
    {
        m2 = other(p,m);
        
        if(!m2->dfs_marked)
        {
            dfs_assign(m2, pos, x);
        }
        
        p = p->next;
    }
}

//depth-first search used to order markers
void dfs_order(struct conf*c,struct marker*m,double dist)
{
    struct edgelist*p=NULL;
    struct marker*m2=NULL;
    
    //mark this node as visited
    assert(!m->dfs_marked);
    m->dfs_marked = 1;
    
    //check if this is a new maximum distance from the root node
    if(dist > c->dfs_maxdist)
    {
        c->dfs_maxdist = dist;
        c->dfs_maxmarker = m;
    }
    
    //visit all unmarked adjacent nodes
    p = m->adj_list;
    
    while(p)
    {
        m2 = other(p,m);
        
        if(!m2->dfs_marked)
        {
            m2->dfs_parent = p;
            dfs_order(c, m2, dist + p->e->cm);
        }
        
        p = p->next;
    }
}

//return the other marker (ie not m)
struct marker*other(struct edgelist*p,struct marker*m)
{
    if(p->e->m1 == m) return p->e->m2;
    return p->e->m1;
}

void append_edge(struct edgelist**list,struct edgelist*p)
{
    //move to end of linked list
    while(*list != NULL) list = &((*list)->next);
    
    //append new item
    *list = p;
}

/*
split edges by linkage group
*/
void split_edges(struct earray*ea,struct map*mp)
{
    unsigned i;
    struct edge*e=NULL;
    struct earray*p=NULL;
    
    //alloc edge arrays
    assert(mp->earrays = calloc(mp->nlgs,sizeof(struct earray*)));
    for(i=0; i<mp->nlgs; i++) assert(mp->earrays[i] = calloc(1,sizeof(struct earray)));
    
    //count edges per lg, ignore edges which bridge two lgs
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];
        if(e->m1->lg != e->m2->lg) continue; //ignore edge if bridges two lgs
        mp->earrays[e->m1->lg]->nedgemax += 1; //count egdes per lg
    }
    
    //alloc space for all edges
    for(i=0; i<mp->nlgs; i++)
    {
        p = mp->earrays[i];
        assert(p->array = calloc(p->nedgemax,sizeof(struct edge*)));
    }
    
    //for(i=0; i<c->nlgs; i++) printf("lg %u has %u edges\n",i,c->lg_nedges[i]);
    
    //split edges into their own array per lg
    for(i=0; i<ea->nedges; i++)
    {
        e = ea->array[i];

        if(e->m1->lg != e->m2->lg) continue; //ignore if bridges two lgs
        
        p = mp->earrays[e->m1->lg];
        p->array[p->nedges] = e;
        p->nedges += 1;
    }

    //check
    for(i=0; i<mp->nlgs; i++)
    {
        p = mp->earrays[i];
        assert(p->nedgemax == p->nedges);
    }
    
    //unsigned j;
    //for(i=0; i<c->nlgs; i++) for(j=0; j<c->lg_nedges[i]; j++) printf("lg %u edges %u %s %s\n",i,j,c->lg_edges[i][j]->m1->name,c->lg_edges[i][j]->m2->name);
}

//sort the markers by group-root marker uid
int mcomp_func(const void*_m1, const void*_m2)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    struct marker*p1=NULL;
    struct marker*p2=NULL;
    
    m1 = *((struct marker**)_m1);
    m2 = *((struct marker**)_m2);
    
    p1 = find_group(m1);
    p2 = find_group(m2);
    
    if(p1->uid < p2->uid) return -1;
    if(p1->uid > p2->uid) return 1;
    return 0;
}

/*
sort markers by linkage group
set their lg property
split into separate arrays
*/
void split_markers(struct lg*p,struct map*mp)
{
    unsigned i,lg;
    int prev,ctr;
    struct marker*m=NULL;
    
    //sort markers by group uid
    qsort(p->array,p->nmarkers,sizeof(struct marker*),mcomp_func);
    
    //for(i=0; i<c->nmarkers; i++) printf("%p\n",(void*)find_group(c->array[i]));
    
    //alloc space for lgs
    assert(mp->lgs = calloc(mp->nlgs,sizeof(struct lg*)));

    //assign sequential lg numbers, count markers
    prev = -1;
    ctr = -1;
    for(i=0; i<p->nmarkers; i++)
    {
        m = find_group(p->array[i]);
        
        if((int)m->uid != prev)
        {
            ctr += 1;
            prev = (int)m->uid;
            assert(mp->lgs[ctr] = calloc(1,sizeof(struct lg)));
        }
        
        p->array[i]->lg = ctr;
        mp->lgs[ctr]->nmarkers += 1;
    }
    
    assert(ctr == (int)mp->nlgs-1);
    
    
    //printf("nlgs=%u\n",c->nlgs);
    //for(i=0; i<c->nmarkers; i++) printf("%s %u\n",c->array[i]->name,c->array[i]->lg);

    //count markers per lg
    //for(i=0; i<p->nmarkers; i++) mp->lgs[p->array[i]->lg] += 1;

    //for(i=0; i<c->nlgs; i++) printf("lg %u has %u markers\n",i,c->lg_nmarkers[i]);

    //allocate space for markers
    for(i=0; i<mp->nlgs; i++)
    {
        assert(mp->lgs[i]->array = calloc(mp->lgs[i]->nmarkers,sizeof(struct marker*)));
        assert(mp->lgs[i]->name = calloc(21,sizeof(char)));
        sprintf(mp->lgs[i]->name,"%03d",i);
    }
    
    //split markers into separate lgs
    prev = -1;
    ctr = 0;
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        lg = m->lg;
        if((int)lg != prev) ctr = 0;
        
        mp->lgs[lg]->array[ctr] = m;
        
        ctr += 1;
        prev = lg;
    }
    
    //unsigned j;
    //for(i=0; i<c->nlgs; i++) for(j=0; j<c->lg_nmarkers[i]; j++) printf("lg %u marker %u %s\n",i,j,c->lg_markers[i][j]->name);
}

//save lg
//treat as phased and imputed
//phasing and imputing can easily be ignored if required when data are reloaded
void save_lg_markers(struct conf*c,const char*fname,struct lg*p)
{
    FILE*f=NULL;
    struct marker*m=NULL;
    unsigned i,j;
    
    assert(f = fopen(fname,"wb"));
    
    fprintf(f,"; group %s markers %u\n",p->name,p->nmarkers);
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
    
        fprintf(f,"%s ",m->name);
        switch(m->type)
        {
            case LMTYPE:
                fprintf(f,"<lmxll> ");
                if(m->phase[0]) fprintf(f,"{1-}");
                else            fprintf(f,"{0-}");
                
                for(j=0; j<c->nind; j++)
                {
                    if(m->orig[0][j] == MISSING)       fprintf(f," --");
                    else if(m->orig[0][j])             fprintf(f," lm");
                    else                               fprintf(f," ll");
                }
                break;
                
            case NPTYPE:
                fprintf(f,"<nnxnp> ");
                if(m->phase[1]) fprintf(f,"{-1}");
                else            fprintf(f,"{-0}");
                
                for(j=0; j<c->nind; j++)
                {
                    if(m->orig[1][j] == MISSING)       fprintf(f," --");
                    else if(m->orig[1][j])             fprintf(f," np");
                    else                               fprintf(f," nn");
                }
                break;
                
            case HKTYPE:
                fprintf(f,"<hkxhk> ");
                if(m->phase[0]) fprintf(f,"{1");
                else            fprintf(f,"{0");
                if(m->phase[1]) fprintf(f,"1}");
                else            fprintf(f,"0}");
                
                for(j=0; j<c->nind; j++)
                {
                    if(m->orig[0][j] == MISSING || m->orig[1][j] == MISSING)
                    {
                        fprintf(f," --");
                        continue;
                    }
                    
                    if(m->orig[0][j]) fprintf(f," k");
                    else              fprintf(f," h");
                    if(m->orig[1][j]) fprintf(f,"k");
                    else              fprintf(f,"h");
                }
                break;
                
            default:
                assert(0);
        }
        fprintf(f,"\n");
    }
    
    fclose(f);
}

//save lg map positions
void save_lg_map(const char*fname,struct lg*p)
{
    FILE*f=NULL;
    struct marker*m=NULL;
    unsigned i,x;
    
    assert(f = fopen(fname,"wb"));
    
    fprintf(f,"group %s ; markers %u\n",p->name,p->nmarkers);
    
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        fprintf(f,"%s",m->name);
        for(x=0; x<3; x++)
        {
            if(m->pos[x] == NO_POSN) fprintf(f,"\t%8s","NA");
            else                     fprintf(f,"\t%8.4f",m->pos[x]);
        }
        fprintf(f,"\n");
    }
    
    fclose(f);
}

/*
for phase-known test data, checking phasing for errors
*/
void check_phase(struct conf*c,struct map*mp)
{
    struct marker*m=NULL;
    struct lg*p=NULL;
    unsigned i,j,x,total_errors,total_count;
    int errors,count;
    
    total_errors = 0;
    total_count = 0;
    
    //per linkage group
    for(i=0; i<mp->nlgs; i++)
    {
        p = mp->lgs[i];
        
        for(x=0; x<2; x++)
        {
            errors = 0;
            count = 0;
            
            for(j=0; j<p->nmarkers; j++)
            {
                m = p->array[j];
                if(!m->data[x]) continue;
                count += 1;
                if(m->phase[x] != m->oldphase[x]) errors += 1;
            }
            
            if(errors > count / 2) total_errors += count - errors; //treat as antiphase
            else                   total_errors += errors;
            
            total_count += count;
        }
    }
    
    fprintf(c->flog,"#phasing errors %u %f\n",total_errors, (double)total_errors/total_count);
}

