#include "create_map.h"

#include "rjvparser.h"

struct conf*init_conf(int argc, char **argv)
{
    struct conf*c=NULL;
    
    assert(c = calloc(1,sizeof(struct conf)));

    rjvparser("output-file|STRING|!|output map specification file",&c->out);
    rjvparser("random-seed|UNSIGNED|0|random number generator seed (0=use system time)",&c->prng_seed);
    rjvparser("numb-lgs|UNSIGNED|10|divide map into this number of equally sized linkage groups",&c->nlgs);
    rjvparser("map-size|FLOAT|100.0|total map size in centimorgans",&c->map_size);
    rjvparser("marker-density|FLOAT|1.0|average markers per centimorgan",&c->density);
    rjvparser("prob-both|FLOAT|0.3333|probability marker is heterozygous in both parents",&c->prob_hk);
    rjvparser("prob-maternal|FLOAT|0.333|probability marker is heterozygous only in maternal parent",&c->prob_lm);
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\nuniform random placement of markers on a map using specified constraints");
    
    //check for unset options or invalid options
    assert(c->out != NULL);
    
    //do other setup
    c->nmarkers = round(c->map_size * c->density);
    c->lg_size = c->map_size / c->nlgs;
    
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

//qsort compare function
int comp_func(const void*_p1, const void*_p2)
{
    struct marker*m1;
    struct marker*m2;
    
    m1 = *((struct marker**)_p1);
    m2 = *((struct marker**)_p2);
    
    if(m1->lg < m2->lg) return -1;
    if(m1->lg > m2->lg) return 1;
    if(m1->pos < m2->pos) return -1;
    if(m1->pos > m2->pos) return 1;
    return 0;
}

void create_map(struct conf*c)
{
    unsigned i;
    struct marker*m=NULL;
    double dval;
    
    assert(c->map = calloc(c->nmarkers,sizeof(struct marker*)));
    assert(c->nmark = calloc(c->nlgs,sizeof(unsigned)));
    
    //create marker
    for(i=0; i<c->nmarkers; i++)
    {
        assert(m = calloc(1,sizeof(struct marker)));
        c->map[i] = m;
        
        m->lg = rand()%c->nlgs;
        m->pos = drand48() * c->lg_size;
        c->nmark[m->lg] += 1;
        
        dval = drand48();
        
        if(dval < c->prob_hk)
        {
            m->type = 3;
            m->phase[0] = drand48()<0.5?'0':'1';
            m->phase[1] = drand48()<0.5?'0':'1';
            strcpy(m->type_str,"<hkxhk>");
        }
        else if(dval < c->prob_hk + c->prob_lm)
        {
            m->type = 1;
            m->phase[0] = drand48()<0.5?'0':'1';
            m->phase[1] = '-';
            strcpy(m->type_str,"<lmxll>");
        }
        else
        {
            m->type = 2;
            m->phase[0] = '-';
            m->phase[1] = drand48()<0.5?'0':'1';
            strcpy(m->type_str,"<nnxnp>");
        }
    }
    
    //sort by lg and pos
    qsort(c->map,c->nmarkers,sizeof(struct marker*),comp_func);
}

void save_map(struct conf*c)
{
    struct marker*m=NULL;
    unsigned i,j,itmp;
    unsigned*mnumb=NULL;
    FILE*f=NULL;
    
    //create random, unique marker numbering
    assert(mnumb = calloc(c->nmarkers,sizeof(unsigned)));
    for(i=0; i<c->nmarkers; i++) mnumb[i] = i;
    for(i=0; i<c->nmarkers; i++)
    {
        j = rand() % c->nmarkers;
        SWAP(mnumb[i],mnumb[j],itmp);
    }
    
    assert(f = fopen(c->out,"wb"));
    fprintf(f,"#markers %u lgs %u\n",c->nmarkers,c->nlgs);
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->map[i];
        
        fprintf(f,
                "M%08x %s {%c%c} %3u %8.6f\n",
                mnumb[i],
                m->type_str,
                m->phase[0],m->phase[1],
                m->lg,
                m->pos);
    }
    
    fclose(f);
}
