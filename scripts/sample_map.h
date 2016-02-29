#ifndef _RJV_CROSSLINK_SAMPLE_H_
#define _RJV_CROSSLINK_SAMPLE_H_
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <argp.h>
#include <sys/time.h>
#include <time.h>

#define BUFFER 10000

#define XOR(x,y) (!(x) != !(y))

/*swap two values over*/
#define SWAP(a,b,tmp) (tmp) = (a), (a) = (b), (b) = (tmp)

#define LMTYPE 1
#define NPTYPE 2
#define HKTYPE 3

//which value to represent missing data
#define MISSING 255

/*
data defining a single marker
*/
struct marker
{
    char*name;               /*marker name*/
    unsigned type;           /*1=lm,2=np,3=hk*/
    unsigned phase[2];       /*[0]=mat phase [1]=pat phase*/

    unsigned lg;             /*linkage group*/
    double pos;              /*map position (cM)*/
};

/*
global parameters and the marker list
*/
struct conf
{
    char*inp;             //input file
    char*out;             //output file
    char*orig;            //output without errors/missing file

    unsigned nind;                //number of individuals in population
    unsigned prng_seed;           //PRNG seed, 0=>using system time
    double prob_missing;          //prob genotype is missing
    double prob_error;            //prob genotype call is wrong
    double prob_type_error;       //prob lm type is called as np or vice versa
    unsigned map_func;            //which mapping function, 1=haldane,2=kosambi

    unsigned nmarkers;
    unsigned nlgs;

    struct marker**map;   //list of markers map[i]-> marker
    unsigned***data;      //genotype data stored per individual data[indiv][2][marker]-> genotype code
    unsigned*nmark;       //how many markers per lg
};

void load_map(struct conf*c);
void save_data(struct conf*c,char*fname,unsigned orig);
void sample_map(struct conf*c);
void sample_individual(struct conf*c,unsigned**data);
double inverse_kosambi(double d);
double inverse_haldane(double d);
void random_order(struct conf*c);
void hide_hk(struct conf*c);
void apply_errors(struct conf*c);
struct conf*init_conf(int argc, char **argv);
#endif
