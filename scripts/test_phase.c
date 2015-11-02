#include "gg_phase.h"

#include <assert.h>

void string2bits(const char*str,BITTYPE*bits)
{
    unsigned i,y,z,n;
    
    n = strlen(str);
    
    for(i=0; i<n; i++)
    {
        y = i / BITSIZE;
        z = i % BITSIZE;
        if(str[i] == '1') bits[y] = SET_BIT(bits[y],z);
    }
}

BITTYPE random_bits64()
{
    BITTYPE x=0;
    unsigned i;
    
    for(i=0; i<64; i++) if(drand48() < 0.5) x += (BITTYPE)1 << i;
    
    return x;
}

void test_phase()
{
    struct conf*c;
    BITTYPE mask1=0,mask2=0,bits1=0,bits2=0;
    double rf,lod;
    
    assert(c = calloc(1,sizeof(struct conf)));
    c->nvar = 1;
    
    string2bits("1100111111",&mask1);
    string2bits("1110111111",&mask2);
    
    string2bits("1010011011",&bits1);
    string2bits("1100011110",&bits2);
    
    printf("mask1=0x%016llx bits1=0x%016llx mask2=0x%016llx bits1=0x%016llx\n",(long long unsigned)mask1,
                                                                               (long long unsigned)bits1,
                                                                               (long long unsigned)mask2,
                                                                               (long long unsigned)bits2);
    
    calc_lod(c,&mask1,&bits1,&mask2,&bits2,&rf,&lod);
    
    printf("rf=%f lod=%f\n",rf,lod);
}

int main(int argc,char*argv[])
{
    srand48(time(NULL));
    srand(time(NULL));
    
    assert(argc);
    assert(argv);
    
    test_phase();
    
    return 0;
}


