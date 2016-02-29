#include "create_map.h"

#ifndef NDEBUG

int main(int argc,char**argv)
{
    struct conf*c=NULL;
    
    c = init_conf(argc,argv);
    
    create_map(c);
    
    save_map(c);
    
    return 0;
}

#endif
