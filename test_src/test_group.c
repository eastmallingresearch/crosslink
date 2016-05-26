//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "gg_group.h"

#include <assert.h>

void string2bits(const char*str,VARTYPE*code)
{
    unsigned i,n;
    
    n = strlen(str);
    
    for(i=0; i<n; i++)
    {
        switch(str[i])
        {
            case 'a':
                code[i] = HH_CALL;
                break;
            case 'b':
                code[i] = KK_CALL;
                break;
            case 'h':
                code[i] = HK_CALL;
                break;
            default:
                assert(0);
        }
    }
}

void test_group()
{
    struct conf*c;
    unsigned n=20,cxr_flag;
    VARTYPE*code1=NULL;
    VARTYPE*code2=NULL;
    double lod,rf;
    
    assert(c = calloc(1,sizeof(struct conf)));
    c->nind = n;
    c->em_maxit = 10;
    c->em_tol = 1e-4;

    assert(code1 = calloc(n,sizeof(VARTYPE)));
    assert(code2 = calloc(n,sizeof(VARTYPE)));
    
    string2bits("bhbhhahahabhbhhahaha",code1);
    string2bits("ahahabhbhbahahhbhbhb",code2);
    
    calc_lod_hk(c,code1,code2,&lod,&rf,&cxr_flag);
    
    printf("lod=%f rf=%f cxr_flag=%u\n",lod,rf,cxr_flag);
}

int main(int argc,char*argv[])
{
    srand48(time(NULL));
    srand(time(NULL));
    
    assert(argc);
    assert(argv);
    
    test_group();
    
    return 0;
}


