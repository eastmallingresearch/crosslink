//Crosslink, Copyright (C) 2016  NIAB EMR
#ifndef _RJV_CROSSLINK_CREATE_H_
#define _RJV_CROSSLINK_CREATE_H_

/*swap two values over*/
#define SWAP(a,b,tmp) (tmp) = (a), (a) = (b), (b) = (tmp)

/*max size of lg or marker name*/
#define BUFFER 1000

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <sys/time.h>
#include <math.h>
#include <argp.h>
#include <ctype.h>

/*
data defining a single marker
*/
struct marker
{
    unsigned char type;      /*1=lm,2=np,3=hk*/
    char type_str[8];        /*<lmxll> <nnxnp> <hkxhk>*/
    char phase[2];           /*[0]=mat phase [1]=pat phase*/

    unsigned lg;       /*linkage group*/
    double pos;        /*map position (cM)*/
};

/*
global parameters and the marker list
*/
struct conf
{
    //command line options
    char*out;             //output filename
    unsigned prng_seed;   //0 => use system time, >0 => deterministic behaviour
    unsigned nlgs;        //number of linkage groups
    double map_size;      //total map size (centimorgans)
    double density;       //marker density (per centimorgan)
    double prob_hk;       /*prob marker is hk*/
    double prob_lm;       /*prob marker is lm given it's not an hk*/

    //derived from map_size and density
    unsigned nmarkers;    //number of markers
    double lg_size;       //cM size per LG
    
    struct marker**map;   /*list of markers*/
    unsigned*nmark;       /*how many markers per lg*/
};

struct conf*init_conf(int argc, char **argv);
void create_map(struct conf*c);
void save_map(struct conf*c);

#endif
