#include "sample_map.h"

#ifndef NDEBUG

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    
    c = init_conf(argc,argv);
    
    load_map(c);
    
    sample_map(c);
    
    //output each linkage group to a separate file
    //output original, error free marker data
    if(c->orig != NULL) save_data(c,c->orig,1);

    if(c->prob_missing+c->prob_error+c->prob_type_error > 0.0) apply_errors(c);
    
    random_order(c);

    //save marker data into a single file, with errors
    save_data(c,c->out,0);
    
    return 0;
}

#endif
