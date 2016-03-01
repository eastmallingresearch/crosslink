#include "crosslink_ga.h"
#include "crosslink_utils.h"
#include "crosslink_group.h"

//calculate the 2pt version of the map order optimisation objective
//(either a quantised version of map distance or a normalised representation of recombination count)
//or lookup a previously calculated cached value
//x=0 return the value appropriate for maternal information only
//x=1 return the value appropriate for paternal information only
unsigned lookup_2pt(struct conf*c,struct marker*m1,struct marker*m2,unsigned x)
{
    unsigned itmp,i,j,cache_val;
    double rf;
    
    //ensure j <= i
    i = m1->uid;
    j = m2->uid;
    if(j > i) SWAP(i,j,itmp);
    
    //return cached value if present
    //zero indicates value not calculated yet
    //2pt rf only uses cache[0] as mat/pat distances are never different
    if(c->ga_cache)
    {
        if(c->cache[0][i][j] != 0) return c->cache[0][i][j] - 1;
    }
    
    rf = calc_2pt_rf(c,m1,m2,x);

    //total map distance is the objective function
    if(c->ga_optimise_dist)
    {
        //calculate quantised distance in units of 1/100th cM
        cache_val = QUANTISED_DIST(rf);
    }
    //total number of recombinations is the objective function
    //cache actually store in units of 1/10 of a recombination
    //to reduce normalisation rounding errors
    else
    {
        //convert rf back into a normalised R as if N == nind
        cache_val = CONVERT_RF2R(rf);
    }
 
    //cache the R value
    if(c->ga_cache)
    {
        c->cache[0][i][j] = cache_val + 1;
    }
    
    return cache_val;
}

double calc_2pt_rf(struct conf*c,struct marker*m1,struct marker*m2,unsigned x)
{
    unsigned R,N,c0,c1;
    double rf;
    
    if(m1->type == HKTYPE && m2->type == HKTYPE) //HK vs HK, already phased
    {
        //rf applicable to either map (2pt rf does not allow mat and pat dist to differ)
        
        //find whether phase is cxc,rxr,cxr or rxc
        c0 = c1 = 0;
        if(m1->phase[0] == m2->phase[0]) c0 = 1;  //cx?
        if(m1->phase[1] == m2->phase[1]) c1 = 1;  //?xr
        
        if((c0 && c1) || (!c0 && !c1))
        {
            //phase is cxc or rxr
            rf = calc_rf_hk_implicit(c,m1->code,m2->code,c0);
        }
        else
        {
            //phase is cxr or rxc
            rf = calc_rf_hk_explicit(c,m1->code,m2->code); 
        }
        
        if(rf == NO_RFLOD)
        {
            //failed to produce a valid rf value
            if(c->flog && !c->warn_norf)
            {
                fprintf(c->flog,"#warning: during ordering at least one hk-hk marker comparison "
                                "failed to give a usable rf value: large distance(s) assigned may be bogus\n");
            }
            c->warn_norf = 1;
            
            //assign large distance
            rf = 1.0;
        }
    }
    else //LM vs (LM / HK) or NP vs (NP / HK), using info from already-phased m1/m2->data
    {
        //rf for mat or pat map only - no info about the other is available
        calc_RN_simple(c,m1,m2,x,&R,&N);
    
        if(N == 0)
        {
            //warn about lack of usable information
            if(c->flog && !c->warn_noinfo)
            {
                fprintf(c->flog,"#warning: during ordering at least one marker-marker comparison "
                                "contained no usable genotype information: large distance(s) assigned may be bogus\n");
            }
            c->warn_noinfo = 1;
            
            //assign large distance
            R = N = 1;
        }
        
        rf = (double)R / N;
    }
 
    //assuming markers are correctly phased, rf > 0.5 is sampling error not repulsion phase linkage
    //0.499 limits max dist to about 310 cM
    if(rf > MAX_RF) rf = MAX_RF;
    
    return rf;
}

//calculate R and N between two hk markers which are in cxr or rxc phase
//using the explicit formula from Maliepaard
double calc_rf_hk_explicit(struct conf*c,VARTYPE*m1,VARTYPE*m2)
{
    unsigned i,j,N;
    unsigned n[9] = {0,0,0,0,0,0,0,0,0};
    double sum,val;
    
    N = 0;
    for(i=0; i<c->nind; i++)
    {
        if(m1[i] == MISSING || m2[i] == MISSING) continue;
        N += 1;
        j = 3* m1[i] + m2[i];
        n[j] += 1;
    }
    
    //no usable information
    if(N == 0) return NO_RFLOD;

    sum = n[0] + n[2] + n[4] + n[6] + n[8]; //n[0] ...n[8] correspond to n1...n9 in Table 2.3
    val = 0.25 - sum / (2.0 * (double)N);   //val e [-1/4, 1/4]
    
    //rf is real
    if(val >= 0.0) return 0.5 - sqrt(val);      //r e [0,1/2]
    
    //rf is imaginary
    return NO_RFLOD;
}

//calculate R and N between two hk markers which are in cxc or rxr phase
//using the implicit EM formula from Maliepaard
double calc_rf_hk_implicit(struct conf*c,VARTYPE*m1,VARTYPE*m2,unsigned c0)
{
    unsigned i,j,N,utmp;
    unsigned n[9] = {0,0,0,0,0,0,0,0,0};
    double rf,rf_new,eval,sum;
    
    N = 0;
    for(i=0; i<c->nind; i++)
    {
        if(m1[i] == MISSING || m2[i] == MISSING) continue;
        N += 1;
        j = 3* m1[i] + m2[i];
        n[j] += 1;
    }
    
    //no usable information
    if(N == 0) return NO_RFLOD;
    
    //repulsion phase (rxr)
    if(!c0)
    {
        //switch values for repulsion phase
        SWAP(n[0],n[2],utmp);
        SWAP(n[6],n[8],utmp);
    }
    
    //calc ML rf estimate suitable for cxc / rxr phasing using Expectation Maximisation
    rf = 0.25;
    sum = n[1] + n[3] + n[5] + n[7] + 2.0 * ((double)n[2] + n[6]);
    
    for(i=0; i<c->ga_em_maxit; i++)
    {
        rf_new = (sum + 2.0 * (double)n[4] * rf * rf
                 / (1.0 - 2.0 * rf * (1.0 - rf)))          // >= 0.5
                 / (2.0 * (double)N);
        
        eval = fabs(rf_new - rf);
        rf = rf_new;
        
        if(eval < c->ga_em_tol) break;
    }
    
    if(i >= c->ga_em_maxit || rf < 0.0 || rf > 1.0)
    {
        //rf failed to converge on a sensible value
        return NO_RFLOD;
    }
    
    return rf;
}

//multipoint equivalent of lookup_2pt
//assumes most hks have been imputed (but still checks for missing values)
unsigned lookup_mpt(struct conf*c,struct marker*m1,struct marker*m2,unsigned x)
{
    unsigned itmp,i,j,N,R,cache_val;
    double rf;

    /*ensure j <= i*/
    i = m1->uid;
    j = m2->uid;
    if(j > i) SWAP(i,j,itmp);
    
    /*
    return cached values if present
    zero indicates values not calculated yet
    */
    if(c->ga_cache)
    {
        if(c->cache[x][i][j] != 0) return c->cache[x][i][j] - 1;
    }
    
    //rf for mat or pat map only - no info about the other is available
    calc_RN_simple(c,m1,m2,x,&R,&N);

    if(N == 0)
    {
        //warn about lack of usable information
        if(c->flog && !c->warn_noinfo)
        {
            fprintf(c->flog,"#warning: during ordering at least one marker-marker comparison "
                            "contained no usable genotype information: large distance(s) assigned may be bogus\n");
        }
        c->warn_noinfo = 1;
        
        //assign large distance
        R = N = 1;
    }
    
    rf = (double)R / N;
 
    //assuming markers are correctly phased, rf > 0.5 is sampling error not repulsion phase linkage
    //0.499 limits max dist to about 310 cM
    if(rf > MAX_RF) rf = MAX_RF;

    //total map distance is the objective function
    if(c->ga_optimise_dist)
    {
        //calculate quantised distance in units of 1/100th cM
        cache_val = QUANTISED_DIST(rf);
    }
    //total number of recombinations is the objective function
    //cache actually store in units of 1/10 of a recombination
    //to reduce normalisation rounding errors
    else
    {
        //convert rf back into a normalised R as if N == nind
        cache_val = CONVERT_RF2R(rf);
    }
 
    //cache the R value
    if(c->ga_cache)
    {
        c->cache[0][i][j] = cache_val + 1;
    }
    
    return cache_val;
}

/*
adapted from openvswitch, apache 2.0 licensed as of 2015-09-06
http://openvswitch.org/pipermail/dev/2013-December/034915.html
count number of bits set in a 64 bit integer
*/
unsigned count64(uint64_t val)
{
    const uint64_t h55 = UINT64_C(0x5555555555555555);
    const uint64_t h33 = UINT64_C(0x3333333333333333);
    const uint64_t h0F = UINT64_C(0x0F0F0F0F0F0F0F0F);
    const uint64_t h01 = UINT64_C(0x0101010101010101);
    uint64_t x;

    x = val;
    x -= (x >> 1) & h55;             
    x = (x & h33) + ((x >> 2) & h33);
    x = (x + (x >> 4)) & h0F;        
    return (x * h01) >> 56;          
}

/*
find total combined map distance of mat and pat maps
by scanning the whole map
*/
unsigned calc_events(struct conf*c,struct marker**marray)
{
    unsigned i,j,x,total_dist;
    
    total_dist = 0;
    for(i=0; i<c->nmarkers-1; i++)
    {
        //struct conf*c,struct marker*m1,struct marker*m2
        for(x=0; x<2; x++)
        {
            /*count maternal/paternal events between i (if not null) and next non null (if any)*/
            if(marray[i]->data[x])
            {
                for(j=i+1; j<c->nmarkers; j++) if(marray[j]->data[x]) break;

                if(j < c->nmarkers) total_dist += c->lookup(c,marray[i],marray[j],x);
            }
        }
    }
    
    return total_dist;
}

//count recombination events lost/gained given a set of break points in the map
//consider only parent x 0=mat 1=pat
//brk[i] => break between marker brk[i] and brk[i]+1
//brk must be sorted into ascending order
unsigned local_events2(struct conf*c,struct marker**marray,unsigned x,const int*_brk,int nbrk)
{
    int i,j,k,l,min,max,events;
    int brk[10];
    
    //work with local copy to avoid unexpected side effects to caller
    //when brk array is modified
    assert(nbrk <= 10);
    for(i=0; i<nbrk; i++) brk[i] = _brk[i];
    
    min = 0;
    max = c->nmarkers-1;
    events = 0;

    for(i=0; i<nbrk; i++)
    {
        if(brk[i] > max) break;
        
        //find first non-missing data before the break
        for(j=brk[i]; j>=min; j--) if(marray[j]->data[x]) break;
        
        //if hit start of map, this break will not produce any events
        if(j < min)
        {
            if(brk[i] >= 0) min = brk[i]; //stop subsequent breaks scanning this region again
            continue;
        }
        
        //find first non-missing data after the break
        for(k=brk[i]+1; k<=max; k++) if(marray[k]->data[x]) break;
        
        //if hit reached end of map, this and all subsequent breaks will not produce any events
        if(k > max) break;

        //while we are not the last break in the list
        while(i < nbrk-1)
        {
            //if the next break is beyond the non-missing data we found, proceed as normal
            if(k <= brk[i+1]) break;
            
            //we went past break i+1 so it will not contribute any events
            //remove it from list
            //shift subsequent breaks up the list by one
            for(l=i+2; l<nbrk; l++) brk[l-1] = brk[l];
            nbrk -= 1;
        }
        
        events += c->lookup(c,marray[j],marray[k],x);
    }

    return events;
}

//find how many recombination events will be lost
//after the mutation is applied to dst
unsigned dec_events(struct conf*c,struct mutation*op,struct marker**dst)
{
    unsigned events = 0;
    int brk[3];
    int nbrk;
    
    if(op->src1 < op->dst1)
    {
        brk[0] = op->src1-1;
        brk[1] = op->src2;
        brk[2] = op->dst2;
        nbrk=3;
    }
    else if(op->src1 == op->dst1)
    {
        brk[0] = op->src1-1;
        brk[1] = op->src2;
        nbrk=2;
    }
    else
    {
        brk[0] = op->dst1-1;
        brk[1] = op->src1-1;
        brk[2] = op->src2;
        nbrk=3;
    }
    
    events += local_events2(c,dst,0,brk,nbrk); //maternal recombinations
    events += local_events2(c,dst,1,brk,nbrk); //paternal recombinations

    return events;
}

//find how many recombination events have been gained
//after the mutation was applied to dst
unsigned inc_events(struct conf*c,struct mutation*op,struct marker**dst)
{
    unsigned events = 0;
    int brk[3];
    int nbrk;
    
    if(op->src1 < op->dst1)
    {
        brk[0] = op->src1-1;
        brk[1] = op->dst1-1;
        brk[2] = op->dst2;
        nbrk=3;
    }
    else if(op->src1 == op->dst1)
    {
        brk[0] = op->dst1-1;
        brk[1] = op->dst2;
        nbrk=2;
    }
    else
    {
        brk[0] = op->dst1-1;
        brk[1] = op->dst2;
        brk[2] = op->src2;
        nbrk=3;
    }
    
    events += local_events2(c,dst,0,brk,nbrk); //maternal recombinations
    events += local_events2(c,dst,1,brk,nbrk); //paternal recombinations

    return events;
}

//generate a random mutation operation
//move {src1,...src2} -> {dst1,...dst2} inclusive
//if inv move {src1,...src2} -> {dst2,...dst1} inclusive
void generate_mutation(struct conf*c,struct mutation*op)
{
    int size,move;
    double dval;

    dval = drand48();

    //hop mutation (segment move with size = 1, inv = 0)
    if(dval < c->ga_prob_hop)
    {
        size = 1;
        op->inv = 0; //might run faster with inv=1 to prevent call to memcpy?

        //choose hop distance
        move = round(drand48() * (double)c->nmarkers * c->ga_max_hop);
        if(move < 1) move = 1;
        if(drand48() < 0.5) move = -move;
    }
    //segment move
    else if(dval < c->ga_prob_hop+c->ga_prob_move)
    {
        //choose segment size
        size = (int)round(drand48() * (double)c->nmarkers * c->ga_max_mvseg);
        if(size > (int)c->nmarkers) size = c->nmarkers;
        if(size < 1) size = 1; //min size is 1

        //optional invert
        if(drand48() < c->ga_prob_inv) op->inv = 1;
        else                           op->inv = 0;

        //choose movement distance
        move = round(drand48() * (double)c->nmarkers * c->ga_max_mvdist);
        if(move < 1) move = 1;
        if(drand48() < 0.5) move = -move;
    }
    //segment invert (in-place)
    else
    {
        //choose segment size
        size = (int)round(drand48() * (double)c->nmarkers * c->ga_max_seg);
        if(size > (int)c->nmarkers) size = c->nmarkers;

        //must invert
        op->inv = 1;
        
        //min size is 2
        if(size < 1) size = 2;
        
        //no move
        move = 0;
    }
    
    //choose src segment
    op->src1 = rand() % (c->nmarkers - size + 1);
    op->src2 = op->src1 + size - 1;
    if(op->src2 >= (int)c->nmarkers) op->src2 = c->nmarkers - 1;

    //find destination segment
    op->dst1 = op->src1 + move;
    op->dst2 = op->src2 + move;

    if(op->dst1 < 0)
    {
        op->dst1 = 0;
        op->dst2 = op->dst1 + size - 1;
    }
    else
    if(op->dst2 >= (int)c->nmarkers)
    {
        op->dst2 = c->nmarkers - 1;
        op->dst1 = op->dst2 - size + 1;
    }
    
    /*
    op->src1 = rand() % c->nmarkers;
    op->src2 = rand() % c->nmarkers;
    if(op->src1 > op->src2) SWAP(op->src1,op->src2,tmp);
    size = op->src2 - op->src1 + 1;
    
    op->dst1 = rand() % (c->nmarkers-size+1);
    op->dst2 = op->dst1 + size - 1;
    */
}

//copy the mutation from the mutant to the elite
//so that the two become identical again
//without (usually) having to copy the entire array from one to the other
void accept_mutation(struct conf*c,struct mutation*op)
{
    //copy the affected segment
    if(op->src1 < op->dst1)
    {
        memcpy((void*)(c->array+op->src1),(void*)(c->mutant+op->src1),(op->dst2-op->src1+1)*sizeof(struct marker*));
    }
    else
    {
        memcpy((void*)(c->array+op->dst1),(void*)(c->mutant+op->dst1),(op->src2-op->dst1+1)*sizeof(struct marker*));
    }
}

/*
copy the original order back from the elite
so that the two become identical again
without (usually) having to copy the entire array from one to the other
*/
void undo_mutation(struct conf*c,struct mutation*op)
{
    //copy the affected segment
    if(op->src1 < op->dst1)
    {
        memcpy((void*)(c->mutant+op->src1),(void*)(c->array+op->src1),(op->dst2-op->src1+1)*sizeof(struct marker*));
    }
    else
    {
        memcpy((void*)(c->mutant+op->dst1),(void*)(c->array+op->dst1),(op->src2-op->dst1+1)*sizeof(struct marker*));
    }
}

/*apply mutation operation to the array of markers*/
void apply_mutation(struct mutation*op,struct marker**dst,struct marker**src)
{
    unsigned i,size;

    /*calculate segment size*/
    size = op->src2 - op->src1 + 1;
    
    /*move the explicitly selected segment with or without inverting*/
    if(op->inv)
    {
        for(i=0; i<size; i++) dst[op->dst1+i] = src[op->src2-i];
    }
    else
    {
        memcpy((void*)(dst+op->dst1),(void*)(src+op->src1),size*sizeof(struct marker*));
    }

    /*move the implicitly defined segment (without inverting)*/
    if(op->src1 < op->dst1)
    {
        memcpy((void*)(dst+op->src1),(void*)(src+op->src1+size),(op->dst1-op->src1)*sizeof(struct marker*));
    }
    else
    {
        memcpy((void*)(dst+op->dst1+size),(void*)(src+op->dst1),(op->src1-op->dst1)*sizeof(struct marker*));
    }
}

//sort edges into ascending order by map distance regardless of mark types
int ecomp_mapdist_only(const void*_p1, const void*_p2)
{
    struct edge*p1=NULL;
    struct edge*p2=NULL;
    
    p1 = *((struct edge**)_p1);
    p2 = *((struct edge**)_p2);
    
    if(p1->cm < p2->cm) return -1;
    if(p1->cm > p2->cm) return 1;
    return 0;
}

//produce initial approx ordering using the mst method
void mst_approx_order(struct conf*c)
{
    FILE*f=NULL;
    
    //all vs all distance/recomb count
    ga_build_elist(c);
    
    //sort edges into ascending cM
    if(c->ga_mst_nonhk) qsort(c->elist,c->nedge,sizeof(struct edge*),ecomp_mapdist_nonhk);
    else                qsort(c->elist,c->nedge,sizeof(struct edge*),ecomp_mapdist_only);
    
    //produce approx order for maternal and paternal maps
    order_markers(c,c->nmarkers,c->array,c->nedge,c->elist,0);
    order_markers(c,c->nmarkers,c->array,c->nedge,c->elist,1);
    
    //produce combined map positions and sort by them
    comb_map_positions(c,c->nmarkers,c->array,0,1);
    
    //output mst map approx ordering before ga optimisation
    if(c->mstmap != NULL)
    {
        f = fopen(c->mstmap,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->mstmap);
            exit(1);
        }

        print_map(c->nmarkers,c->array,f,0,NULL);
        
        fclose(f);
    }
}    

void ga_build_elist(struct conf*c)
{
    unsigned i,j,R,N,R2,N2,S,nonhk;
    double lod,rf,s;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    
    for(i=0; i<c->nmarkers-1; i++)
    {
        m1 = c->array[i];
        
        for(j=i+1; j<c->nmarkers; j++)
        {
            m2 = c->array[j];
            
            //is either marker an HK?
            if(m1->type == HKTYPE || m2->type == HKTYPE) nonhk = 0;
            else                                         nonhk = 1;
            
            //HK vs HK
            if(m1->type == HKTYPE && m2->type == HKTYPE)
            {
                calc_RN_simple(c,m1,m2,0,&R,&N);
                calc_RN_simple(c,m1,m2,1,&R2,&N2);
                N += N2;
                R += R2;
            }
            //LM vs LM or HK
            else if(m1->data[0] && m2->data[0])
            {
                calc_RN_simple(c,m1,m2,0,&R,&N);
            }
            //NP vs NP or HK
            else if(m1->data[1] && m2->data[1])
            {
                calc_RN_simple(c,m1,m2,1,&R,&N);
            }
            
            if(N == 0) continue;
            
            rf = (double)R / N;
            if(rf > MAX_RF) rf = MAX_RF;
            
            //calculate linkage LOD
            s = 1.0 - rf;
            S = N - R;
            
            lod = 0.0;
            if(s > 0.0) lod += S * LOG10(2.0*s);
            if(rf > 0.0) lod += R * LOG10(2.0*rf);
            
            if(lod < c->ga_mst_minlod) continue;
            
            add_edge(c,m1,m2,lod,rf,0,c->map_func(rf),nonhk);
        }
    }
    
    if(c->flog) fprintf(c->flog,"#%u edges added\n",c->nedge);
}

//optimise the map order using a genetic algorithm
void order_map(struct conf*c)
{
    unsigned i;
    struct mutation mut;
    uint64_t elite_events,mutant_events,events1,events2;

    if(c->cycle_ctr == 0)
    {
        if(c->ga_skip_order1) return; //skip first ordering
        c->lookup = lookup_2pt;       //use two point rf calculation
    }
    else
    {
        c->lookup = lookup_mpt;     //use multipoint rf based on gibbs imputations
    }
    
    //blank out the R matrix as gibbs may have changed the genotype calls
    if(c->ga_cache) reset_r_matrix(c);
    
    //compress data into bitstrings
    if(c->gg_bitstrings) compress_to_bitstrings(c,c->nmarkers,c->array);
    
    //produce an initial approx ordering using the MST method
    if(c->cycle_ctr > 0)
    {
        //ga_use_mst defines which cycle(s) to use the MST method
        if(c->cycle_ctr <= c->ga_use_mst) mst_approx_order(c);
    }
    
    //count recombination events in initial ordering
    //not strictly required as all we need to know is whether
    //the mutant is better than the elite
    //but very useful for testing
    elite_events = calc_events(c,c->array);
    
    //initialise mutant as copy of elite
    memcpy((void*)c->mutant,(void*)c->array, c->nmarkers*sizeof(struct marker*));
    
    //generate initial logging info
    if(c->flog)
    {
        fprintf(c->flog,"#ordering map for %u iterations\n",c->ga_iters);
        
        if(c->ga_report)
        {
            fprintf(c->flog,"#iteration map_length_cm");
            if(c->gg_show_pearson) fprintf(c->flog," abs(pearson_correlation_coefficient)");
            fprintf(c->flog,"\n");
        }
    }
    
    for(i=0; i<c->ga_iters; i++)
    {
        //DEBUG
        //memcpy((void*)order1,(void*)c->array, c->nmarkers*sizeof(struct marker*)); //make a copy of the elite
        //for(j=0; j<c->nmarkers; j++) assert(c->array[j] == c->mutant[j]); //check elite == mutant

        //define a mutation
        generate_mutation(c,&mut);
        
        //count recombination events that will be lost after the mutation is applied
        events1 = dec_events(c,&mut,c->mutant);
        
        //apply mutation to mutant
        apply_mutation(&mut,c->mutant,c->array);
        
        //count recombination events that have been gained since the mutation was applied
        events2 = inc_events(c,&mut,c->mutant);

        //calculate total recombination events in mutant
        mutant_events = elite_events - events1 + events2;
        
        //check the value agrees with a direct calculation
        //assert(calc_events(c,c->mutant) == mutant_events);
        
        //accept mutant if it is the same or better
        //by applying the same mutation to the elite
        if(mutant_events <= elite_events)
        {
            elite_events = mutant_events;
            accept_mutation(c,&mut);
        }
        //undo the mutation if rejected
        else
        {
            undo_mutation(c,&mut);
            
            //DEBUG - check elite and mutant were put back to how they were
            //for(j=0; j<c->nmarkers; j++) assert(order1[j] == c->array[j] && order1[j] == c->mutant[j]);
        }
        
        //report current progress
        if(c->flog && c->ga_report)
        {
            if(i % c->ga_report == 0)
            {
                fprintf(c->flog,"%u %lu",i+1,elite_events/100);
                if(c->gg_show_pearson) fprintf(c->flog," %f",calc_pearson(c->nmarkers,c->array));
                fprintf(c->flog,"\n");
            }
        }
    }
    
    if(c->flog && c->ga_report && c->gg_show_pearson)
    {
        fprintf(c->flog,"#final pearson %f\n",calc_pearson(c->nmarkers,c->array));
    }
}
