#include "gg_map.h"

#include <assert.h>

unsigned failures = 0;

unsigned alt_popcnt64(uint64_t x)
{
    unsigned i,count=0;
    
    for(i=0; i<64; i++) if(x & ((uint64_t)1 << i)) count += 1;
    
    return count;
}

unsigned alt_popcnt32(uint32_t x)
{
    unsigned i,count=0;
    
    for(i=0; i<32; i++) if(x & ((uint32_t)1 << i)) count += 1;
    
    return count;
}

uint64_t random_bits64()
{
    uint64_t x;
    unsigned i;
    
    for(i=0; i<64; i++) if(drand48() < 0.5) x += (uint64_t)1 << i;
    
    return x;
}

uint32_t random_bits32()
{
    uint32_t x;
    unsigned i;
    
    for(i=0; i<32; i++) if(drand48() < 0.5) x += (uint32_t)1 << i;
    
    return x;
}

void test_popcnt()
{
    uint64_t bits64,bits64_2;
    uint32_t bits32,bits32_2; 
    unsigned i,j;

    for(i=0; i<100; i++)
    {
        //generate random bits
        bits64 = random_bits64();
        bits32 = random_bits32();
        
        //check that alternative popcnt implementations give the same results
        assert(alt_popcnt64(bits64) == __builtin_popcountll(bits64));
        assert(alt_popcnt64(bits64) == count64(bits64));
        assert(alt_popcnt32(bits32) == __builtin_popcount(bits32));
        
        //check that any single bit change is detected
        for(j=0; j<64; j++)
        {
            bits64_2 = bits64 ^ ((uint64_t)1 << j);
            assert(__builtin_popcountll(bits64) != __builtin_popcountll(bits64_2));
            assert(count64(bits64) != count64(bits64_2));
        }
        for(j=0; j<32; j++)
        {
            bits32_2 = bits32 ^ ((uint32_t)1 << j);
            assert(__builtin_popcount(bits32) != __builtin_popcount(bits32_2));
        }
    }
}

void time_popcnt64_builtin(unsigned iters)
{
    uint64_t bits64;
    unsigned i,count=0;

    bits64 = random_bits64();

    for(i=0; i<iters; i++)
    {
        //check that alternative popcnt implementations give the same results
        count += __builtin_popcountll(bits64);
    }
}

void time_popcnt32_builtin(unsigned iters)
{
    uint32_t bits32;
    unsigned i,count=0;

    bits32 = random_bits32();

    for(i=0; i<iters; i++)
    {
        //check that alternative popcnt implementations give the same results
        count += __builtin_popcount(bits32);
    }
}

void time_popcnt32_alt(unsigned iters)
{
    uint32_t bits32;
    unsigned i,count=0;

    bits32 = random_bits32();

    for(i=0; i<iters; i++)
    {
        //check that alternative popcnt implementations give the same results
        count += alt_popcnt32(bits32);
    }
}

void time_popcnt64_openvswitch(unsigned iters)
{
    uint64_t bits64;
    unsigned i,count=0;

    bits64 = random_bits64();

    for(i=0; i<iters; i++)
    {
        //check that alternative popcnt implementations give the same results
        count += count64(bits64);
    }
}

void time_popcnt64_alt(unsigned iters)
{
    uint64_t bits64;
    unsigned i,count=0;

    bits64 = random_bits64();

    for(i=0; i<iters; i++)
    {
        //check that alternative popcnt implementations give the same results
        count += alt_popcnt64(bits64);
    }
}

int main(int argc,char*argv[])
{
    long unsigned time1,time2,time3,time4,time5,time6;
    
    srand48(get_time());
    srand(get_time()+1234);
    
    assert(argc);
    assert(argv);
    
    test_popcnt();
    
    time1 = get_time();
    time_popcnt64_builtin(10000);
    
    time2 = get_time();
    time_popcnt64_openvswitch(10000);
    
    time3 = get_time();
    time_popcnt64_alt(10000);

    time4 = get_time();
    time_popcnt32_builtin(10000);
    
    time5 = get_time();
    time_popcnt32_alt(10000);

    time6 = get_time();

    printf("__builtin_popcountll=%lu\n",time2-time1);
    printf("count64=%lu\n",time3-time2);
    printf("alt64=%lu\n",time4-time3);
    printf("__builtin_popcount=%lu\n",time5-time4);
    printf("alt32=%lu\n",time6-time5);
    
    return failures;
}


