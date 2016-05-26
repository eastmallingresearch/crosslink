//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "gg_map.h"

#include <assert.h>
/*
void to_bitstring(struct conf*c,VTYPE*data,BTYPE*bits,BTYPE*mask)
{
    unsigned i,y,z;

    for(i=0; i<c->nind; i++)
    {
        y = i / BSIZE;
        z = i % BSIZE;
        
        if(data[i] == MISSING)
        {
            bits[y] = CLEAR_BIT(bits[y],z);
            mask[y] = SET_BIT(bits[y],z);
        }
        else if(data[i] == 0)
        {
            bits[y] = CLEAR_BIT(bits[y],z);
            mask[y] = CLEAR_BIT(bits[y],z);
        }
        else //data[i] == 1
        {
            bits[y] = SET_BIT(bits[y],z);
            mask[y] = CLEAR_BIT(bits[y],z);
        }
    }
}
*/

void test_to_bitstring()
{
    struct conf*c=NULL;
    unsigned i;
    char str[] = "1-";
    VTYPE*data=NULL;
    BTYPE*bits=NULL;
    BTYPE*mask=NULL;
    
    c = calloc(1,sizeof(struct conf));
    c->nind = strlen(str);
    c->nvar = (c->nind + BSIZE - 1) / BSIZE;
    
    assert(data = calloc(c->nind,sizeof(VTYPE)));
    assert(bits = calloc(c->nvar,sizeof(BTYPE)));
    assert(mask = calloc(c->nvar,sizeof(BTYPE)));
    
    for(i=0; i<c->nind; i++)
    {
        if(str[i] == '0') data[i] = 0;
        if(str[i] == '1') data[i] = 1;
        if(str[i] == '-') data[i] = MISSING;
    }
    
    to_bitstring(c,data,bits,mask);
    
    for(i=0; i<c->nvar; i++) printf("%lu %lu\n",bits[i],mask[i]);
    printf("\n");
}

int main(int argc,char*argv[])
{
    srand48(get_time());
    srand(get_time()+1234);
    
    assert(argc);
    assert(argv);
    
    test_to_bitstring();
    
    return 0;
}


