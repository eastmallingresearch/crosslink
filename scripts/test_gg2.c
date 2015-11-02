#include "gg_map.h"

#include <assert.h>

void test_count_hkerrors()
{
    struct conf*c=NULL;
    struct marker*m=NULL;
    unsigned i,count1,count2;
    
    assert(c = calloc(1,sizeof(struct conf)));
    
    c->nmarkers = 1;
    c->nind = 10;
    
    assert(c->elite = calloc(1,sizeof(struct marker*)));
    assert(c->elite[0] = calloc(1,sizeof(struct marker)));
    m = c->elite[0];
    
    m->type = HKTYPE;
    m->phase[0] = rand() % 2;
    m->phase[1] = rand() % 2;
    
    assert(m->orig[0] = calloc(c->nind,sizeof(VTYPE)));
    assert(m->orig[1] = calloc(c->nind,sizeof(VTYPE)));
    assert(m->data[0] = calloc(c->nind,sizeof(VTYPE)));
    assert(m->data[1] = calloc(c->nind,sizeof(VTYPE)));
    
    count1 = 0;
    for(i=0; i<c->nind; i++) 
    {
        if(rand() % 2) m->orig[0][i] = 1;
        if(rand() % 2) m->orig[1][i] = 1;
        if(rand() % 2) m->data[0][i] = 1;
        if(rand() % 2) m->data[1][i] = 1;
        
        if(m->phase[0] == 0){ if(m->orig[0][i] != m->data[0][i]) count1 += 1;}
        else                { if(m->orig[0][i] == m->data[0][i]) count1 += 1;}
        
        if(m->phase[1] == 0){ if(m->orig[1][i] != m->data[1][i]) count1 += 1;}
        else                { if(m->orig[1][i] == m->data[1][i]) count1 += 1;}
    }
    
    count2 = count_hkerrors(c);
    
    printf("count1=%u count2=%u\n",count1,count2);
    assert(count1 == count2);
}

int main(int argc,char*argv[])
{
    unsigned i;
    
    assert(argc);
    assert(argv);
    
    srand48(time(NULL));
    srand(time(NULL)+1234);
    
    for(i=0; i<100; i++) test_count_hkerrors();
    
    return 0;
}


