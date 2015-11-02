#include "create_map.h"

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
    
    assert(c->map = calloc(c->nmarkers,sizeof(struct marker*)));
    assert(c->nmark = calloc(c->nlgs,sizeof(unsigned)));
    
    /*create marker*/
    for(i=0; i<c->nmarkers; i++)
    {
        assert(m = calloc(1,sizeof(struct marker)));
        c->map[i] = m;
        
        m->lg = rand()%c->nlgs;
        m->pos = drand48() * c->lg_size;
        c->nmark[m->lg] += 1;
        
        if(drand48() < c->prob_hk)
        {
            m->type = 3;
            m->phase[0] = drand48()<0.5?'0':'1';
            m->phase[1] = drand48()<0.5?'0':'1';
            strcpy(m->type_str,"<hkxhk>");
        }
        else if(drand48() < c->prob_lm)
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
    
    /*sort by lg and pos*/
    qsort(c->map,c->nmarkers,sizeof(struct marker*),comp_func);
}

void save_map(struct conf*c)
{
    char buff[BUFFER];
    struct marker*m=NULL;
    unsigned i;
    FILE*f;
    
    assert(f = fopen(c->out,"wb"));
    
    fprintf(f,"#markers %u lgs %u\n",c->nmarkers,c->nlgs);
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->map[i];
        sprintf(buff,c->marker_fmt,m->lg,m->pos,m->type_str[1]);
        fprintf(f,"%s %s {%c%c} %3u %8.3f\n",buff,m->type_str,m->phase[0],m->phase[1],m->lg,m->pos);
    }
    
    fclose(f);
}
