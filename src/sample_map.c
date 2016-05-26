//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "sample_map.h"

#include "rjvparser.h"

char*type_str[] = {"NULL","<lmxll>","<nnxnp>","<hkxhk>"};
char*phase_str = "01";

struct conf*init_conf(int argc, char **argv)
{
    struct conf*c=NULL;
    
    assert(c = calloc(1,sizeof(struct conf)));
    rjvparser("input-file|STRING|!|input map specification file",&c->inp);
    rjvparser("output-file|STRING|!|output genotype file including any errors",&c->out);
    rjvparser("orig-dir|STRING|-|output grouped genotype files without any errors",&c->orig);
    rjvparser("random-seed|INTEGER|0|random number generator seed, 0=use system time",&c->prng_seed);
    rjvparser("samples|INTEGER|200|number of offspring to simulate",&c->nind);
    rjvparser("prob-missing|FLOAT|0.0|probability a genotype call is missing",&c->prob_missing);
    rjvparser("prob-error|FLOAT|0.0|probability a genotype call is incorrect",&c->prob_error);
    //rjvparser("prob-type-error|FLOAT|0.0|probability a maternal/paternal marker is misclassfied as a paternal/maternal marker",&c->prob_type_error);
    rjvparser("map-function|INTEGER|1|1=Haldane, 2=Kosambi",&c->map_func);
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\nsimulate genotype data from an existing map for a given number of F1 offspring");

    //seed random number generator
    if(c->prng_seed != 0)
    {
        srand(c->prng_seed);
    }
    else
    {
        struct timeval tv;
        gettimeofday(&tv,NULL);
        srand(tv.tv_sec * 1000000 + tv.tv_usec);
    }
    
    srand48(rand());
    
    return c;
}

void save_data(struct conf*c,char*fname,unsigned orig)
{
    struct marker*m=NULL;
    FILE*f=NULL;
    unsigned i,j,lg=9999999,hk1,hk2;
    char buffer[BUFFER];
    
    if(!orig) assert(f = fopen(fname,"wb"));

    for(i=0; i<c->nmarkers; i++)
    {
        //for orignal data output each gl to a different file
        if(orig && c->map[i]->lg != lg)
        {
            sprintf(buffer,"%s/%03d.orig",fname,c->map[i]->lg);
            if(f != NULL) fclose(f);
            assert(f = fopen(buffer,"wb"));
            lg = c->map[i]->lg;
        }
        
        m = c->map[i];
        fprintf(f,"%s %s",m->name,type_str[m->type]);
        
        if(orig)
        {
            //output true phase
            switch(m->type)
            {
                case LMTYPE:
                    if(m->phase[0])      fprintf(f," {1-}");
                    else                 fprintf(f," {0-}");
                    break;
                case NPTYPE:
                    if(m->phase[1])      fprintf(f," {-1}");
                    else                 fprintf(f," {-0}");
                    break;
                case HKTYPE:
                    if(m->phase[0])      fprintf(f," {1");
                    else                 fprintf(f," {0");
                    if(m->phase[1])      fprintf(f,"1}");
                    else                 fprintf(f,"0}");
                    break;
                default:
                    assert(0);
            }
        }
        else
        {
            //hide phase
            switch(m->type)
            {
                case LMTYPE:
                    fprintf(f," {0-}");
                    break;
                case NPTYPE:
                    fprintf(f," {-0}");
                    break;
                case HKTYPE:
                    fprintf(f," {00}");
                    break;
                default:
                    assert(0);
            }
        }
        
        for(j=0; j<c->nind; j++)
        {
            if(c->data[j][0][i] == MISSING || c->data[j][0][i] == MISSING)
            {
                fprintf(f," --");
                continue;
            }
            
            switch(m->type)
            {
                case LMTYPE:
                    if(XOR(c->data[j][0][i],m->phase[0])) fprintf(f," lm");
                    else                                  fprintf(f," ll");
                    break;
                case NPTYPE:
                    if(XOR(c->data[j][1][i],m->phase[1])) fprintf(f," np");
                    else                                  fprintf(f," nn");
                    break;
                case HKTYPE:
                    hk1 = XOR(c->data[j][0][i],m->phase[0]);
                    hk2 = XOR(c->data[j][1][i],m->phase[1]);
                    
                    if(orig)
                    {
                        //output full information
                        if(hk1) fprintf(f," k");
                        else    fprintf(f," h");
                        if(hk2) fprintf(f,"k");
                        else    fprintf(f,"h");
                    }
                    else
                    {
                        //hide hk verus kh information
                        if(hk1 == hk2)
                        {
                            if(hk1) fprintf(f," kk");
                            else    fprintf(f," hh");
                        }
                        else
                        {
                            fprintf(f," hk");
                        }
                    }
                    break;
                default:
                    assert(0);
            }
        }

        fprintf(f,"\n");
    }
    
    fclose(f);
}

void load_map(struct conf*c)
{
    FILE*f=NULL;
    char buff[BUFFER];
    char name[BUFFER];
    char type[BUFFER];
    char phase[BUFFER];
    unsigned i;
    struct marker*m=NULL;
    
    assert(f = fopen(c->inp,"rb"));
    
    /*read number of markers*/
    assert(fgets(buff,BUFFER-2,f));
    assert(sscanf(buff,"%*s %u %*s %u",&c->nmarkers,&c->nlgs) == 2);

    /*alloc space*/
    assert(c->map = calloc(c->nmarkers,sizeof(struct marker*)));
    
    assert(c->nmark = calloc(c->nlgs,sizeof(unsigned)));
    
    /*read markers*/
    for(i=0; i<c->nmarkers; i++)
    {
        assert(fgets(buff,BUFFER-2,f));
        assert(m = calloc(1,sizeof(struct marker)));
        c->map[i] = m;
        assert(sscanf(buff,"%s %s %s %u %lf",name,type,phase,&m->lg,&m->pos) == 5);
        assert(m->name = calloc(strlen(name)+1,sizeof(char)));
        strcpy(m->name,name);
        
        c->nmark[m->lg] += 1;
        
        switch(type[1])
        {
            case 'l':
                m->type = LMTYPE;
                m->phase[0] = phase[1]=='0'?0:1;
                break;
            case 'n':
                m->type = NPTYPE;
                m->phase[1] = phase[2]=='0'?0:1;
                break;
            case 'h':
                m->type = HKTYPE;
                m->phase[0] = phase[1]=='0'?0:1;
                m->phase[1] = phase[2]=='0'?0:1;
                break;
            default:
                assert(0);
                break;
        }
    }
    
    fclose(f);
}

/*
count recombs between first two markers,assuming both are hks
*/
void count_recombs(struct conf*c,unsigned***data)
{
    unsigned i,events_m=0,events_p=0;
    
    for(i=0; i<c->nind; i++)
    {
        events_m += XOR(data[i][0][0],data[i][0][1]);
        events_p += XOR(data[i][1][0],data[i][1][1]);
    }
    
    printf("m=%u p=%u\n",events_m,events_p);
}

void sample_map(struct conf*c)
{
    unsigned i;
    
    assert(c->data = calloc(c->nind,sizeof(unsigned**)));
    
    for(i=0; i<c->nind; i++)
    {
        assert(c->data[i] = calloc(2,sizeof(unsigned*)));
        assert(c->data[i][0] = calloc(c->nmarkers,sizeof(unsigned))); //maternal
        assert(c->data[i][1] = calloc(c->nmarkers,sizeof(unsigned))); //paternal
        
        sample_individual(c,c->data[i]);
    }
    
    //count_recombs(c,c->data);
} 
    
//convert from distance (in centimorgans) to recombination fraction [0,0.5]
double inverse_kosambi(double d)
{
    return 0.5 * tanh(fabs(d)/50.0);
}
  
//convert from distance (in centimorgans) to recombination fraction [0,0.5]
double inverse_haldane(double d)
{
    return 0.5 * (1.0 - exp(-fabs(d)/50.0));
}
    
//randomise map order
void random_order(struct conf*c)
{
    unsigned i,j,k,utmp;
    struct marker*mtmp;
    
    for(i=0; i<c->nmarkers; i++)
    {
        k = rand()%c->nmarkers;
        SWAP(c->map[i],c->map[k],mtmp);
        
        for(j=0; j<c->nind; j++)
        {
            SWAP(c->data[j][0][i],c->data[j][0][k],utmp);
            SWAP(c->data[j][1][i],c->data[j][1][k],utmp);
        }
    }
}

/*
change kh to hk
*/
void hide_hk(struct conf*c)
{
    unsigned i,j;
    struct marker*m=NULL;    
    
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->map[i];
        if(m->type != HKTYPE) continue; //not an hkxhk
        
        for(j=0; j<c->nind; j++)
        {
            if(XOR(c->data[j][0][i],m->phase[0]) == XOR(c->data[j][1][i],m->phase[1])) continue; //not an hk or kh
            
            if(XOR(c->data[j][0][i],m->phase[0]))
            {
                //change kh to hk
                c->data[j][0][i] = !c->data[j][0][i];
                c->data[j][1][i] = !c->data[j][1][i];
            }
        }
    }
}

void sample_individual(struct conf*c,unsigned**data)
{
    unsigned chr[2],i;
    unsigned lg=99999999;
    struct marker*m=NULL;
    double dist,rf;
    double (*mfunc)(double)=NULL;
    
    switch(c->map_func)
    {
        case 1:
            mfunc = inverse_haldane;
            break;
        case 2:
            mfunc = inverse_kosambi;
            break;
        default:
            assert(0);
    }

    chr[0] = rand()%2;
    chr[1] = rand()%2;
    
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->map[i];
        
        if(lg != m->lg)
        {
            //pick initial mat/pat chromosome
            //for the linkage group
            chr[0] = rand()%2;
            chr[1] = rand()%2;
            lg = m->lg;
        }
        
        switch(m->type)
        {
            case LMTYPE: //lm
                data[0][i] = chr[0];
                break;
            case NPTYPE://np
                data[1][i] = chr[1];
                break;
            case HKTYPE://hk
                data[0][i] = chr[0];
                data[1][i] = chr[1];
                break;
            default:
                assert(0);
        }
        
        //decide whether recombination happens before next marker
        if(i == c->nmarkers-1) continue;    //no following marker
        if(c->map[i+1]->lg != lg) continue; //next marker not on same linkage group
        
        dist = c->map[i+1]->pos - c->map[i]->pos;
        rf = mfunc(dist);
        
        if(drand48() < rf) chr[0] = !chr[0];
        if(drand48() < rf) chr[1] = !chr[1];
    }
}

void apply_errors(struct conf*c)
{
    unsigned i,j;//,utmp;
    struct marker*m=NULL;
    
    for(i=0; i<c->nmarkers; i++)
    {
        for(j=0; j<c->nind; j++)
        {
            //apply genotyping error
            if(drand48() < c->prob_error) c->data[j][0][i] = !(c->data[j][0][i]);
            if(drand48() < c->prob_error) c->data[j][1][i] = !(c->data[j][1][i]);
     
            //create missing data
            if(drand48() < c->prob_missing)
            {
                c->data[j][0][i] = MISSING;
                c->data[j][1][i] = MISSING;
            }
        }
        
        m = c->map[i];
        if(m->type == HKTYPE) continue;
        
        //create marker typing error
        //if(drand48() >= c->prob_type_error) continue;
        //m->type = (m->type==LMTYPE)?NPTYPE:LMTYPE;
        //SWAP(m->phase[0],m->phase[1],utmp);
        //for(j=0; j<c->nind; j++) SWAP(c->data[j][0][i],c->data[j][1][i],utmp);
    }
}
