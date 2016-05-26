//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "gg_group.h"

#include <assert.h>

void test_unionfind()
{
    struct marker**array=NULL;
    struct marker*m=NULL;
    unsigned i,j,n=40000;
    
    assert(array = calloc(n,sizeof(struct marker*)));
    
    for(i=0; i<n; i++)
    {
        assert(m = calloc(1,sizeof(struct marker)));
        array[i] = m;
        
        m->uid = i;
        m->parent = m;
        m->rank = 1;
    }
    
    for(i=0; i<n-1; i++)
    {
        for(j=i+1; j<n; j++)
        {
            if(array[i]->uid % 3 == array[j]->uid % 3) union_groups(array[i],array[j]);
        } 
    }
    
    for(i=0; i<100; i++)
    {
        m = find_group(array[i]);
        printf("%u %u\n",array[i]->uid,m->uid);
    }
    for(i=n-100; i<n; i++)
    {
        m = find_group(array[i]);
        printf("%u %u\n",array[i]->uid,m->uid);
    }
}

int main(int argc,char*argv[])
{
    srand48(time(NULL));
    srand(time(NULL)+1234);
    
    assert(argc);
    assert(argv);
    
    test_unionfind();
    
    return 0;
}


