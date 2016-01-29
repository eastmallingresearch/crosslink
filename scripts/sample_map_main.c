#include "sample_map.h"
#include "/home/vicker/git_repos/rjvbio/rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parsestr(argc,argv,"out",&c->out,0,NULL);
    parsestr(argc,argv,"orig",&c->orig,0,NULL);
    parseuns(argc,argv,"nind",&c->nind,1,200);
    parseuns(argc,argv,"prng_seed",&c->prng_seed,1,0);
    parseuns(argc,argv,"randomise_order",&c->randomise_order,1,0);
    parseuns(argc,argv,"hide_hk_inheritance",&c->hide_hk_inheritance,1,0);
    parseuns(argc,argv,"omit_phase",&c->omit_phase,1,0);
    parsedbl(argc,argv,"prob_missing",&c->prob_missing,1,0.0);
    parsedbl(argc,argv,"prob_error",&c->prob_error,1,0.0);
    parsedbl(argc,argv,"prob_type_error",&c->prob_type_error,1,0.0);
    parseuns(argc,argv,"map_func",&c->map_func,1,1);
    parseend(argc,argv);
    
    /*seed random number generator(s)*/
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
    
    load_map(c);
    
    sample_map(c);
    
    if(c->randomise_order) random_order(c);

    if(c->orig) save_data(c,c->orig);

    apply_errors(c);
    
    if(c->hide_hk_inheritance) hide_hk(c);

    save_data(c,c->out);
    
    return 0;
}
