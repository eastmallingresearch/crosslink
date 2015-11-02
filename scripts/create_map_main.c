#include "create_map.h"
#include "/home/vicker/git_repos/rjvbio/rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"out",&c->out,0,NULL);
    parsestr(argc,argv,"lg_fmt",&c->lg_fmt,1,"lg%03u");
    parsestr(argc,argv,"marker_fmt",&c->marker_fmt,1,"m%03u_%012.7f%c");
    parseuns(argc,argv,"prng_seed",&c->prng_seed,1,0);
    parseuns(argc,argv,"nmarkers",&c->nmarkers,1,100);
    parseuns(argc,argv,"nlgs",&c->nlgs,1,1);
    parsedbl(argc,argv,"lg_size",&c->lg_size,1,100.0);
    parsedbl(argc,argv,"prob_hk",&c->prob_hk,1,0.3333);
    parsedbl(argc,argv,"prob_lm",&c->prob_lm,1,0.5);
    parseend(argc,argv);
    
    //seed random number generator(s)
    if(c->prng_seed == 0)
    {
        srand48(get_time());
        srand(get_time()+1234);
    }
    else
    {
        srand48(c->prng_seed);
        srand(c->prng_seed+1234);
    }
    
    create_map(c);
    
    save_map(c);
    
    return 0;
}
