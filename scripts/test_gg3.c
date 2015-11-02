#include <assert.h>
#include <math.h>
#include <stdio.h>

unsigned failures = 0;

double inverse_kosambi(double d)
{
    return 0.5 * tanh(2.0*fabs(d));
}
    
double inverse_haldane(double d)
{
    return 0.5 * (1.0 - exp(-2.0*fabs(d)));
}

double kosambi(double r)
{
    //return 0.25 * log((1.0+2.0*r)/(1.0-2.0*r));
    return 0.5 * atanh(2.0*r);
}

double haldane(double r)
{
    return -0.5 * log(1.0 - 2.0*r);
}

void test_mapping_func()
{
    double d,r;
    
    for(d=0.0; d<=10.0; d+= 0.01)
    {
        printf("%f %f %f %f %f\n",d,
               inverse_kosambi(d),inverse_haldane(d),
               kosambi(inverse_kosambi(d)),haldane(inverse_haldane(d)));
    }
}


int main(int argc,char*argv[])
{
    //srand48(get_time());
    //srand(get_time()+1234);
    
    test_mapping_func();

    
    return failures;
}


