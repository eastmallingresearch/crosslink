#include "create_map.h"

//const char *argp_program_version = "";
//const char *argp_program_bug_address = "";

static char myargp_docs[] = "uniform random placement of markers on a map using specified constraints";

static struct argp_option myargp_options[] =
{
    { "output-file",     'o',  "FILENAME",  0,  "output map file (required)", 0 },
    { "random-seed",     'r',  "INTEGER",   0,  "random number generator seed (defaults to using system time)", 0 },
    { "numb-lgs",        'n',  "INTEGER",   0,  "divide map into this number of equally sized linkage groups (default: 10)", 0 },
    { "map-size",        's',  "FLOAT",     0,  "total map size in centimorgans (default: 100.0)", 0 },
    { "marker-density",  'd',  "FLOAT",     0,  "average markers per centimorgan (default: 1.0)", 0 },
    { "prob-both",       'b',  "FLOAT",     0,  "probability marker is heterozygous in both parents (default: 0.3333)", 0 },
    { "prob-maternal",   'm',  "FLOAT",     0,  "probability marker is heterozygous only in maternal parent (default: 0.3333)", 0 },
    { 0, 0, 0, 0, 0, 0 }
};

static error_t myargp_parser(int key, char *arg, struct argp_state*state)
{
    struct conf*c = state->input;

    switch(key)
    {
        case 'o': //output-file
            c->out = arg;
            break;
        case 'r': //random-seed
            assert(sscanf(arg,"%u",&c->prng_seed) == 1);
            break;
        case 'n': //numb_lgs
            assert(sscanf(arg,"%u",&c->nlgs) == 1);
            break;
        case 's': //map-size
            assert(sscanf(arg,"%lf",&c->map_size) == 1);
            break;
        case 'd': //marker-density
            assert(sscanf(arg,"%lf",&c->density) == 1);
            break;
        case 'b': //prob-both
            assert(sscanf(arg,"%lf",&c->prob_hk) == 1);
            break;
        case 'm': //prob-matermal
            assert(sscanf(arg,"%lf",&c->prob_lm) == 1);
            break;

        default:
            return ARGP_ERR_UNKNOWN;
    }
    
    return 0;
}

static struct argp myargp_argp = { myargp_options, myargp_parser, 0, myargp_docs };

struct conf*init_conf(int argc, char **argv)
{
    struct conf*c=NULL;
    
    assert(c = calloc(1,sizeof(struct conf)));
    
    //set default values here
    c->out = NULL;
    c->prng_seed = 0;
    c->nlgs = 10;
    c->map_size = 100.0;
    c->density = 1.0;
    c->prob_hk = 0.333;
    c->prob_lm = 0.333;
    
    //parse args from command line
    argp_parse (&myargp_argp, argc, argv, 0, 0, c);
    
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
