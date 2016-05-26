//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "crosslink_gibbs.h"
#include "crosslink_ga.h"
#include "crosslink_utils.h"

static unsigned*sort_key_ind=NULL;
static unsigned*reverse_flag=NULL;

//impute inheritance vectors for hk/kh genotypes
//does not support missing values, which must already be imputed before running this
void gibbs_impute(struct conf*c)
{
    unsigned i,hkerror,hkmissing;
    
    if(c->gibbs_samples == 0) return;
    
    //find current position of all hk genotypes in the map
    //randomise their state
    //zero their counters
    gibbs_init(c);
    
    if(c->flog)
    {
        fprintf(c->flog,"#collecting %u gibbs samples using %u burnin iterations and %u subsequent iterations per sample\n",
                c->gibbs_samples,c->gibbs_burnin,c->gibbs_period);
        
        if(c->gibbs_report)
        {
            fprintf(c->flog,"#sample recomb_events");
            if(c->gg_show_hkcheck) fprintf(c->flog," hk_errors pc_hk_errors");
            fprintf(c->flog,"\n");
        }
    }
    
    //collect required number of hk-state samples
    for(i=0; i<c->gibbs_samples; i++)
    {
        if(c->gg_show_bits == 2)
        {
            printf("#bit state at start of gibbs sample %u\n",i+1);
            print_bits(c,c->array,c->gg_pause);
        }

        if(i == 0) gibbs_iterate(c,c->gibbs_burnin,1); //burn-in period
        else       gibbs_iterate(c,c->gibbs_period,0); //sample period
        
        gibbs_sample(c); //update the counters
        
        //report current progress
        if(c->flog && c->gibbs_report)
        {
            if(i % c->gibbs_report == 0)
            {
                fprintf(c->flog,"%u %d",i+1,c->gibbs_total_recomb);
                if(c->gg_show_hkcheck)
                {
                    hkerror = count_hkerrors(c);
                    fprintf(c->flog," %u %f",hkerror,(double)hkerror/c->nhk);
                }
                fprintf(c->flog,"\n");
                fflush(c->flog);
            }
        }
    }
    
    //set each hk to the most common state from the counters
    gibbs_setstate(c);
    
    if(c->flog && c->gibbs_report)
    {
        fprintf(c->flog,"#set hk states to most frequently encountered states\n");
        hkmissing = count_hkmissing(c);
        fprintf(c->flog,"#number of hk states still set to missing %u %f\n",hkmissing,(double)hkmissing/c->nhk);

        if(c->gg_show_hkcheck)
        {
            hkerror = count_hkerrors(c);
            fprintf(c->flog,"#final number of hk errors %u %f\n",hkerror,(double)hkerror/c->nhk);
        }
    }
    
    if(c->gg_show_bits)
    {
        printf("#most frequent bit state across all samples\n");
        print_bits(c,c->array,0);
    }
}

/*
assuming original hk/kh data in file is correct
count number of differences between current state and correct state
*/
unsigned count_hkerrors(struct conf*c)
{
    struct hk*p;
    struct marker*m=NULL;
    unsigned i,count;
    VARTYPE data;
    
    count = 0;
    
    for(i=0; i<c->nhk; i++)
    {
        p = c->hklist[i];
        m = c->array[p->m];
        
        //treat as missing if magnitude less than min_ctr
        if(abs(p->ctr) < (int)c->gibbs_min_ctr) continue; 

        //determine the current imputed maternal state
        if(p->ctr >= 0) data = 1;
        else            data = 0;

        //check against correct value
        if((VARTYPE)XOR(m->orig[0][p->i],m->phase[0]) != data) count += 1;
    }
    
    return count;
}


/*
count number of hk states still set to missing
*/
unsigned count_hkmissing(struct conf*c)
{
    struct marker*m=NULL;
    unsigned i,j,count;
    
    count = 0;
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->array[i];
        if(m->type != HKTYPE) continue;
        
        for(j=0; j<c->nind; j++)
        {
            if(m->data[0][j] == MISSING) count += 1;
        }
    }
    
    return count;
}

/*
count recombination events between two genotype arrays
assumes no missing data
*/
unsigned gibbs_count_events(struct conf*c,VARTYPE*d1,VARTYPE*d2)
{
    unsigned i,events;
    
    events = 0;
    for(i=0; i<c->nind; i++)
    {
        if(d1[i] != d2[i]) events += 1;
    }
    
    return events;
}

/*
this version of the twopoint rf calculation treats all hk / kh as missing
so as to be unaffected by any hk incorrectly imputed, which are likely to be common
near the beginning of a gibbs cycle
*/
double gibbs_twopoint(struct conf*c,struct marker*m1,struct marker*m2,unsigned x)
{
    unsigned i,c0,c1,R,N;
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
    }
    else //LM vs (LM / HK) or NP vs (NP / HK), using info from already-phased m1/m2->data
    {
        N = c->nind;
        R = 0;
        for(i=0; i<c->nind; i++)
        {
            //treat hk / kh genotype calls as missing (even if already imputed)
            if(m1->type == HKTYPE)
            {
                if(m1->code[i] == HK_CALL)
                {
                    N -= 1;
                    continue;
                }
            }
            
            if(m2->type == HKTYPE)
            {
                if(m2->code[i] == HK_CALL)
                {
                    N -= 1;
                    continue;
                }
            }
            
            if(m1->data[x][i] != m2->data[x][i]) R += 1;
        }
        
        //no usable information
        if(N == 0)
        {
            rf = NO_RFLOD;
        }
        else
        {
            rf = (double)R / (double)N;
        }
    }
 
    if(rf == NO_RFLOD)
    {
        //failed to produce a valid rf value
        if(c->flog && !c->warn_nogibbs)
        {
            fprintf(c->flog,"#warning: during gibbs sampling at least one hk-hk marker comparison "
                            "failed to give a usable rf value: small distance(s) assigned may be bogus\n");
        }
        c->warn_nogibbs = 1;
        
        //assign small distance (ie assuming map is well ordered and dense)
        rf = 0.01;
    }
    
    //assuming markers are correctly phased, rf > 0.5 is sampling error not repulsion phase linkage
    //0.499 limits max dist to about 310 cM
    if(rf > MAX_RF) rf = MAX_RF;
    
    return rf;
}

/*
make list of current locations of hk/kh genotypes
randomise current state
zero counters
count initial recombinations between adjacent mat/pat markers
*/
void gibbs_init(struct conf*c)
{
    unsigned i,j,k,x;
    struct marker*m=NULL;
    struct hk*p=NULL;
    
    k = 0;
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->array[i];
        
        //find previous and next adjacent marker
        //in the maternal and paternal maps
        for(x=0; x<2; x++)
        {
            m->prev[x] = NULL; //will stay NULL if edge of map reached
            m->next[x] = NULL;
            
            for(j=i-1; j<c->nmarkers; j--)//assuming underflow to large positive number
            {
                if(c->array[j]->data[x])
                {
                    m->prev[x] = c->array[j];
                    break;
                }
            }
            
            for(j=i+1; j<c->nmarkers; j++)
            {
                if(c->array[j]->data[x])
                {
                    m->next[x] = c->array[j];
                    break;
                }
            }
        }

        if(m->type != HKTYPE) continue; //consider only hk markers
        
        //make list of all hk / kh genotypes
        for(j=0; j<c->nind; j++)
        {
            //ignore if not an hk or kh
            if(m->orig[0][j] == m->orig[1][j]) continue;
            
            assert(k < c->nhk);
            
            //record location of this hk genotype, zero its counter
            p = c->hklist[k];
            p->m = i;   //marker
            p->i = j;   //individual
            p->ctr = 0; //zero counter

            //freshly decode to phased values in case they were set to missing
            m->data[0][j] = XOR(m->orig[0][j],m->phase[0]);
            m->data[1][j] = XOR(m->orig[1][j],m->phase[1]);
            
            //are the states the same after phasing?
            if(m->data[0][j] == m->data[1][j]) p->same = 1;
            else                               p->same = 0;
                        
            //randomise state
            if(drand48() < 0.5)
            {
                m->data[0][j] = !m->data[0][j];
                m->data[1][j] = !m->data[1][j];
            }
            
            k += 1;
        }
    }
    
    /*
    count initial number of recombinations between a marker and the following mat/pat marker
    */
    c->gibbs_total_recomb = 0;
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->array[i];
        
        for(x=0; x<2; x++)
        {
            //calc R between current and next marker (if it exists)
            //also calc two pt rf
            if(m->data[x] && m->next[x])
            {
                m->Rnext[x] = gibbs_count_events(c,m->data[x],m->next[x]->data[x]);
                c->gibbs_total_recomb += m->Rnext[x];
                m->rf_next[x] = gibbs_twopoint(c,m,m->next[x],x);
            }
        }
    }
}

/*
count the total number of recombinations in the map
*/
unsigned gibbs_count_recombs(struct conf*c)
{
    struct marker*m=NULL;
    unsigned i,x;
    int count=0;
    
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->array[i];
        
        //find previous and next adjacent marker
        //in the maternal and paternal maps
        for(x=0; x<2; x++)
        {
            //calc R between current and next marker (if it exists)
            if(m->data[x] && m->next[x])
            {
                count += gibbs_count_events(c,m->data[x],m->next[x]->data[x]);
            }
        }
    }
    
    return count;
}

/*
adjust the counters to reflect the current state
*/
void gibbs_sample(struct conf*c)
{
    unsigned i;
    struct hk*p;
    struct marker*m;
    
    for(i=0; i<c->nhk; i++)
    {
        p = c->hklist[i];
        m = c->array[p->m];
        
        //inc ctr if 1, dec if 0
        if(m->data[0][p->i]) p->ctr += 1;
        else                 p->ctr -= 1;
    }
}

/*
calculate p(MAT==1 | adjacent marker state)
x==0 => consider maternal information
x==1 => consider paternal information
same => are mat and pat allele code the same
*/
double gibbs_calc_prob(struct conf*c,struct hk*p,VARTYPE adj_state,unsigned x,unsigned R,double rf_2pt)
{
    unsigned nind;
    double rf_mpt,rf;
    
    //effect (if any) of individual we are resampling has already been subtracted from R
    nind = c->nind - 1;
    
    //calc multipoint rf
    rf_mpt = (double)R / nind;
    if(rf_mpt > 0.5) rf_mpt = 0.5;
    
    //use weighted average of 2pt and mpt rf
    rf = c->gibbs_twopt * rf_2pt + (1.0 - c->gibbs_twopt) * rf_mpt;
    
    //P(mat==1)
    if(x == 0)
    {
        if(adj_state)
        {
            //p(no recomb)
            return 1.0 - rf;
        }
        else
        {
            //p(recomb)
            return rf;
        }
    }
    //same == 0 =>  calc P(pat==0)
    //same == 1 =>  calc P(pat==1)
    else
    {
        if(adj_state != p->same)
        {
            //p(recomb)
            return rf;
        }
        else
        {
            //p(no recomb)
            return 1.0 - rf;
        }
    }
}

void gibbs_iterate_inner(struct conf*c,struct hk*p)
{
    unsigned mat_state,x;
    double p_prev[2],p_next[2];
    struct marker*m=NULL;
    
    m = c->array[p->m];
    
    /*
    calc prob marker state is 1 for maternal and 0 for paternal
    given each adjacent marker state
    */
    for(x=0; x<2; x++)
    {
        p_next[x] = 0.5; //default p if there is not adjacent marker information
        p_prev[x] = 0.5;
        
        if(m->next[x])
        {
            if(m->data[x][p->i] != m->next[x]->data[x][p->i])
            {
                //subtract the recomb caused by the resampled individual
                m->Rnext[x] -= 1;
                c->gibbs_total_recomb -= 1;
            }
            
            //ignore next marker IF: in unidir mode AND moving forwards AND there is a prev marker available
            if(!(c->unidir_mode) || !(m->prev[x]) || !(reverse_flag[p->i] == 0))
            {
                p_next[x] = gibbs_calc_prob(c,p,m->next[x]->data[x][p->i],x,m->Rnext[x],m->rf_next[x]);
            }
        }

        if(m->prev[x])
        {
            if(m->data[x][p->i] != m->prev[x]->data[x][p->i])
            {
                //subtract the recomb caused by the resampled individual
                m->prev[x]->Rnext[x] -= 1;
                c->gibbs_total_recomb -= 1;
            }

            //ignore prev marker IF: in unidir mode AND moving backwards AND there is a next marker available
            if(!(c->unidir_mode) || !(m->next[x]) || !(reverse_flag[p->i] == 1))
            {
                p_prev[x] = gibbs_calc_prob(c,p,m->prev[x]->data[x][p->i],x,m->prev[x]->Rnext[x],m->prev[x]->rf_next[x]);
            }
        }
    }
    
    //sample a new state based on the probabilities
    mat_state = gibbs_choose_state(c,p_prev[0],p_next[0],p_prev[1],p_next[1]);
    
    //set the new states
    if(mat_state)
    {
        m->data[0][p->i] = 1;
        
        if(p->same) m->data[1][p->i] = 1;
        else        m->data[1][p->i] = 0;
    }
    else
    {
        m->data[0][p->i] = 0;
        
        if(p->same) m->data[1][p->i] = 0;
        else        m->data[1][p->i] = 1;
    }
    
    //adjust Rnext values to reflect the new state
    for(x=0; x<2; x++)
    {
        if(m->next[x])
        {
            if(m->data[x][p->i] != m->next[x]->data[x][p->i])
            {
                m->Rnext[x] += 1;
                c->gibbs_total_recomb += 1;
            }
        }
        
        if(m->prev[x])
        {
            if(m->data[x][p->i] != m->prev[x]->data[x][p->i])
            {
                m->prev[x]->Rnext[x] += 1;
                c->gibbs_total_recomb += 1;
            }
        }
    }

    //check differential R calculation agrees with direct calculation
    //DEBUG!!!
    /*for(x=0; x<2; x++)
    {
        if(m->next[x])
        {
            assert(gibbs_count_events(c,m->data[x],m->next[x]->data[x]) == m->Rnext[x]);
        }
    }*/
}

/*
used to put hklist into a non random order
*/
int gibbs_comp(const void*phk1, const void*phk2)
{
    struct hk*hk1=NULL;
    struct hk*hk2=NULL;
    
    hk1 = *((struct hk**)phk1);
    hk2 = *((struct hk**)phk2);
    
    //sort indivs into ascending order by sort key
    if(sort_key_ind[hk1->i] < sort_key_ind[hk2->i]) return -1;
    if(sort_key_ind[hk1->i] > sort_key_ind[hk2->i]) return 1;

    //sort into ascending or descending map order within each individual
    if(reverse_flag[hk1->i])
    {
        if(hk1->m < hk2->m) return 1;
        else                return -1;
    }
    else
    {
        if(hk1->m < hk2->m) return -1;
        else                return 1;
    }
}

/*
void check_data_integrity(struct conf*c)
{
    unsigned i;
    struct hk*p=NULL;
    struct marker*m=NULL;
    
    for(i=0; i<c->nhk; i++)
    {
        p = c->hklist[i];
        m = c->array[p->m];
        
        if(p->same)
        {
            if(m->data[0][p->i] != m->data[1][p->i]){ watch_variable = 1; assert(0); }
        }
        else
        {
            if(m->data[0][p->i] == m->data[1][p->i]){ watch_variable = 1; assert(0); }
        }
    }
}
*/

void gibbs_iterate(struct conf*c,unsigned iters,unsigned burnin_flag)
{
    unsigned i,j,k,utmp;
    struct hk*ptmp=NULL;
    double coeff,dval;
    
    if(sort_key_ind == NULL)
    {
        assert(sort_key_ind = calloc(c->nind,sizeof(unsigned)));
        assert(reverse_flag = calloc(c->nind,sizeof(unsigned)));
        for(j=0; j<c->nind; j++) sort_key_ind[j] = j;
    }
    
    for(i=0; i<iters; i++)
    {
        //set min prob and twopt
        if(burnin_flag)
        {
            if(iters == 1)  coeff = 0.0;
            else            coeff = (double)i / (iters-1);
            c->gibbs_twopt = (1.0-coeff)*c->gibbs_twopt_1 + coeff*c->gibbs_twopt_2;
            c->gibbs_min_prob = (1.0-coeff)*c->gibbs_min_prob_1 + coeff*c->gibbs_min_prob_2;
        }
        else
        {
            c->gibbs_twopt = c->gibbs_twopt_2;
            c->gibbs_min_prob = c->gibbs_min_prob_2;
        }
        
        //shuffle order of hk list
        for(j=0; j<c->nhk; j++)
        {
            k = rand()%c->nhk;
            SWAP(c->hklist[j],c->hklist[k],ptmp);
        }
        
        //resample in a non-random order
        //based on map order (either forward or backward), but deal with individuals in a random order
        c->unidir_mode = 0;
        dval = drand48();
        if(dval < c->gibbs_prob_unidir + c->gibbs_prob_sequential)
        {
            for(j=0; j<c->nind; j++)
            {
                //randomise order individuals will be processed
                k = rand()%c->nind;//do not put inside the SWAP macro!
                SWAP(sort_key_ind[j], sort_key_ind[k], utmp);
                
                //each indiv is processed in either forward or reverse map order
                if(drand48() < 0.5) reverse_flag[j] = 0;
                else                reverse_flag[j] = 1;
            }
            
            //sort hk list according to the just-chosen ordering
            qsort(c->hklist,c->nhk,sizeof(struct hk*),gibbs_comp);
            
            //choose whether to activate unidirectional mode
            if(dval < c->gibbs_prob_unidir) c->unidir_mode = 1;
        }
        
        //resample each hk state
        for(j=0; j<c->nhk; j++)
        {
            gibbs_iterate_inner(c,c->hklist[j]);
            
            //DEBUG!!!
            //assert(c->gibbs_total_recomb == gibbs_count_recombs(c));
        }
    }
}

/*
pick new states based on the four probabilities
p1 => P(MAT==1)
*/
unsigned gibbs_choose_state(struct conf*c,double p_mat_prev,double p_mat_next,double p_pat_prev,double p_pat_next)
{
    double p1,p0;
    
    //overall conditional prob of 1 for maternal
    p1 = p_mat_prev * p_mat_next * p_pat_prev * p_pat_next;

    //overall conditional prob of 0 for maternal
    p0 = (1.0 - p_mat_prev) * (1.0 - p_mat_next) * (1.0 - p_pat_prev) * (1.0 - p_pat_next);
    
    if(p1 + p0 <= 0.0)
    {
        //pick at random if both prob are zero
        if(drand48() < 0.5) return 0;
        else                return 1;
    }
    
    //ensure both probs are >= min prob (default min_prob is 0.0)
    if(c->gibbs_min_prob)
    {
        if(p0 / (p1 + p0) < c->gibbs_min_prob)
        {
            if(drand48() < c->gibbs_min_prob) return 0;
            else                              return 1;
        }
        
        if(p1 / (p1 + p0) < c->gibbs_min_prob)
        {
            if(drand48() < c->gibbs_min_prob) return 1;
            else                              return 0;
        }
    }

    //pick new states based on the conditional probabilities
    if(drand48() < p0 / (p1 + p0)) return 0;
    else                           return 1;
}

/*
set each hk to the most likely state
*/
void gibbs_setstate(struct conf*c)
{
    unsigned i;
    struct hk*p;
    struct marker*m;
    
    for(i=0; i<c->nhk; i++)
    {
        p = c->hklist[i];
        m = c->array[p->m];
        
        if(c->gg_show_counters) printf("%d\n",p->ctr);

        //if counter magnitude less than threshold set to missing
        if(abs(p->ctr) < (int)c->gibbs_min_ctr)
        {
            m->data[0][p->i] = MISSING;
            m->data[1][p->i] = MISSING;
            continue;
        }
        
        //set to most often encountered state
        if(p->ctr >= 0)
        {
            m->data[0][p->i] = 1;
            
            if(p->same) m->data[1][p->i] = 1;
            else        m->data[1][p->i] = 0;
        }
        else
        {
            m->data[0][p->i] = 0;
            
            if(p->same) m->data[1][p->i] = 0;
            else        m->data[1][p->i] = 1;
        }
    }
}
