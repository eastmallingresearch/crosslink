#ifndef __RJV_GG_COMMONH__
#define __RJV_GG_COMMONH__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <sys/time.h>
#include <math.h>
#include <inttypes.h>
#include <unistd.h>

/*length of longest allowable line in the input file*/
#define BUFFER 30000

//whether to use 64 bit ints for the bitstrings
#define RJV_UINT64

#define LMTYPE 1
#define NPTYPE 2
#define HKTYPE 3

#define HH_CALL 0
#define HK_CALL 1
#define KK_CALL 2

//max allowed rf
#define MAX_RF 0.499

//log base 10 function used for finding the LOD
//a look up table might possibly be faster
#define LOG10(x) log10(x)

//calculation of map distance from rf
//centimorgans scaled up by factor of 100 then quantised to nearest integer
//#define QUANTISED_DIST(x) (unsigned)round(-5000.0 * log(1.0 - 2.0*(double)(x)))
#define QUANTISED_DIST(x) ((unsigned)round(100.0 * c->map_func(x)))

//convert rf into a normalised R as if N==nind
//scale up then quantise
//this allows to capture the difference in rf between eg 1/10,2/10,1/9,2/9 more accurately
#define CONVERT_RF2R(x) ((unsigned)round( (double)(x) * (double)c->nind * 10.0))

//datatype to use for the bit strings
//function to count the number of bits set to 1
//how many bits per BITTYPE assuming 8 bits per byte
#ifdef RJV_UINT64
    typedef uint64_t BITTYPE;
    #define POPCNT(x) __builtin_popcountll(x)
    //#define POPCNT(x) count64(x)
    #define BITSIZE (sizeof(BITTYPE)*8)
#else
    typedef uint32_t BITTYPE;
    #define POPCNT(x) __builtin_popcount(x)
    #define BITSIZE (sizeof(BITTYPE)*8)
#endif

//which datatype to use for genotype data when not compressed
//into bitstrings
typedef unsigned VARTYPE;

//which value to represent missing data
#define MISSING 255

//value to represent unassigned map position
#define NO_POSN -10000.0

//undefined rf or lod
#define NO_RFLOD -100.0

/*
swap two values over
make sure to pass only plain variables to avoid code being evaluated twice
eg SWAP(array[i],array[rand()%n],itmp) will evaluate rand()%n twice to different values!
*/
#define SWAP(a,b,tmp) (tmp) = (a), (a) = (b), (b) = (tmp)

/*logical XOR*/
#define XOR(x,y) (!(x) != !(y))

//manipulate bit i of variable x
#define GET_BIT(x,i)    ((BITTYPE)(x) &  (c->precalc_mask[i]) )
#define SET_BIT(x,i)    ((BITTYPE)(x) |  (c->precalc_mask[i]) )
#define CLEAR_BIT(x,i)  ((BITTYPE)(x) & ~(c->precalc_mask[i]) )
#define FLIP_BIT(x,i)   ((BITTYPE)(x) ^  (c->precalc_mask[i]) )

//set of lgs and earrays
struct map
{
    unsigned nlgs;
    struct lg**lgs;
    struct earray**earrays;
};

//array of edges (marker-marker comparisons)
struct earray
{
    unsigned nedges,nedgemax;
    struct edge**array;
};

//one linkage group
struct lg
{
    char*name;
    unsigned nmarkers;
    struct marker**array;
};

//data defining a single marker
struct marker
{
    char*name;                  //marker name
    unsigned uid;               //sequential uid not related to file or current ordering
    unsigned true_posn;         //for test data: position in true map order, defined by alphabetical sorting of marker names
    unsigned char type;         //1=lm,2=np,3=hk
    unsigned char phase[2];     //[0]=mat phase [1]=pat phase
    unsigned char oldphase[2];  //used for testing

    BITTYPE*bits[2];           //maternal/paternal info condensed into bitstrings
    BITTYPE*mask[2];           //maternal/paternal bitstring representing missing data
    VARTYPE*data[2];           //maternal/paternal inheritance vector, ie including phase information
    VARTYPE*orig[2];           //maternal/paternal raw genotype code, excluding phase information
    VARTYPE*code;              //combined code for mat and pat calls, used for hk vs hk lod calc
    
    //used during gibbs
    struct marker*prev[2];   //for hk markers, where is the previous and next
    struct marker*next[2];   //non-missing maternal and paternal information
    unsigned Rnext[2];       //recombinations between this and the next marker (mat/pat)
    double rf_next[2];       //two-point rf values
    
    double pos[3];           //used for calculating map position

    //union find
    struct marker*uf_parent;
    unsigned uf_rank;
    
    //depth-first search
    unsigned dfs_marked;     
    struct edgelist*dfs_parent;  //edge leading to parent in dfs tree
    
    unsigned lg;                 //which lg does the marker belong to
    
    struct edgelist*adj_list;    //adjacency list of MST edges
    
    struct missing*miss[2];      //missing data imputation array with nind items
};

struct missing
{
    VARTYPE*val;        //val of k+1 nearest genotype calls
    double*rf;          //rf of k+1 nearest markers
    unsigned n;         //how many neighbours are in the list
};

struct hk
{
    unsigned m;    //offset position of marker in current ordering
    unsigned i;    //offset position of individual in genotype data
    unsigned same; //true if mat and pat state are the same (after taking phase into account)
    int ctr;       //used to counter how many times the allele is hk versus kh
};

struct edge
{
    double lod;        //two point lod and rf
    double rf;
    double cm;         //r (or 1-r) converted into centimorgans
    unsigned cxr_flag; //true if this is an hk-hk linkage with cxr or rxc phasing
    unsigned nonhk;    //true if neither marker is an hk
    struct marker*m1;
    struct marker*m2;
};

//wrapper to allow one edge to be in two (or more) linked lists
struct edgelist
{
    struct edge*e;
    struct edgelist*next;
};

/*
global parameters and the marker list
*/
struct conf
{
    char*inp; //input file
    char*out; //output file
    char*log; //log file
    char*map; //output map file
    char*mstmap; //output mstmap file
    char*lg;  //which linkage group to process
    char*outbase; //output filename base
    char*mapbase; //output map filename base
    FILE*flog;
    
    unsigned gg_prng_seed;        //0 => use system time, >0 => deterministic behaviour
    unsigned gg_map_func;         //1=haldane 2=kosambi
    unsigned gg_randomise_order;  //randomise order of markers after loading
    unsigned gg_bitstrings;       //use bitstring representation of the data to count recombinants
    unsigned gg_show_pearson;     //measure how approx ordering agrees with original ordering of test data
    unsigned gg_show_hkcheck;     //assume original hk/kh alleles are correct, write number of discrepancies to log file
    unsigned gg_show_width;       //debug option: how many individuals to show
    unsigned gg_show_height;      //debug option: how many markers to show
    unsigned gg_show_counters;
    unsigned gg_show_initial;     //1 => show data as loaded then quit
    unsigned gg_show_bits;        //debug option: show no. current state each gibbs sample
    unsigned gg_pause;            //wait for ENTER after printing bits

    double   grp_min_lod;           //min LOD score to consider as linkage
    unsigned grp_min_lgs;           //min lgs to allows
    double   grp_em_tol;            //tolerance, EM assumed to have converged once change is <= this value
    unsigned grp_em_maxit;          //max EM iterations before giving up
    unsigned grp_check_phase;       //for test data with known phase, check for phasing errors
    unsigned grp_knn;               //k parameter of kNN imputation
    unsigned grp_detect_matpat;     //test for LM <=> NP linkage when forming LGs
    unsigned grp_fix_type;          //fix incorrect LM <=> NP  marker typing
    
    unsigned ga_gibbs_cycles;//how many overall cycles of ga+gibbs to perform
    unsigned ga_report;      //how often to report ga progress
    unsigned ga_iters;       //how many GA iterations
    unsigned ga_use_mst;     //use MST to approximately order markers at start of cycle 2
    double   ga_mst_minlod;  //min lod to use in MST
    unsigned ga_mst_nonhk;   //prioritise nonhk edges in MST
    unsigned ga_optimise_dist;    //optimise map order using total map distance rather than total recombinations
    unsigned ga_skip_order1; //skip first ordering (assume input ordering is good enough for first hk imputation step)
    double   ga_prob_hop;    //prob mutation is a single marker relocation
    double   ga_max_hop;     //max distance marker can move as proportion of total marker count
    double   ga_prob_move;   //prob mutation is a MOVE versus INVERT in-place
    double   ga_max_mvseg;   //MOVE: max moved segment size as proportion of linkage group
    double   ga_max_mvdist;  //MOVE: max move distance as proportion of linkage group
    double   ga_prob_inv;    //MOVE: prob of invert during move mutation
    double   ga_max_seg;     //INVERT: max segment size as proportion of linkage group
    unsigned ga_cache;       //cache R values in memory (requires nmarkers^2 space)
    double   ga_em_tol;      //tolerance, EM assumed to have converged once change is <= this value
    unsigned ga_em_maxit;    //max EM iterations before giving up
    
    unsigned gibbs_samples;          //how many gibbs samples to collect
    unsigned gibbs_report;           //how often to report gibbs progress
    unsigned gibbs_burnin;           //gibbs burning time
    unsigned gibbs_period;           //iterations per sample
    double   gibbs_prob_sequential;  //resample hks sequentially per individual
    double   gibbs_prob_unidir;      //for sequential resampling, propagate state info unidirectionally as well (ie only take account of the preceeding marker states)
    double   gibbs_min_prob_1;       //prevent prob of either choice being zero
    double   gibbs_min_prob_2;       //prob 1 used at start of burnin, changes linearly to prob 2 by end of burnin
    double   gibbs_min_prob;         //prob 2 used through out sampling
    double   gibbs_twopt_1;          //controls contribution of two-point and multi-point rf in gibbs
    double   gibbs_twopt_2;          //_1 used at start of burningm changes linearly to _2 by end of burnin
    double   gibbs_twopt;            //_2 used throughout sampling
    unsigned gibbs_min_ctr;          //set hk state to missing if counter mag less than threshold
    
    unsigned nmarkers;     //number of markers
    unsigned nind;         //number of individuals in population
    unsigned nvar;         //length of bitstring array (ie how many BITTYPE variables)
    unsigned nhk;          //how many hk alleles to be imputed by gibbs sampler
    unsigned nlgs;         //how many linkage groups were found
    unsigned nedge;        //current number of edges
    unsigned nedgemax;     //size of current edge list
    unsigned nepool;       //used edgelists
    unsigned nepoolmax;    //currently alloced edgelists
    
    unsigned warn_noinfo;  //set if marker-marker pair have no comparable information in ga ordering
    unsigned warn_norf;    //set if hk-hk marker pair did not produce a valid 2pt rf value
    unsigned warn_nogibbs; //set if marker-marker pair have no comparable information in gibbs sampling
    
    BITTYPE*precalc_mask;  //precalculated bit masks at every bit position

    //used by DFS to find furthest marker
    double dfs_maxdist;
    struct marker*dfs_maxmarker;
    
    struct edgelist*epool; //pool of edgelist structs
    struct edge**elist;    //list of egdes
    struct marker**array;  //array of markers
    struct marker**mutant; //array of markers
    struct hk**hklist;     //list of hk/kh allele positions
    
    //markers and edges split into separate linkage groups
    unsigned*lg_nmarkers;
    unsigned*lg_nedges;
    
    struct marker***lg_markers;
    struct edge***lg_edges;
    char**lg_names;

    unsigned**cache[2];         //cached intermarker distances
    unsigned unidir_mode;        //true if resampling using unidirectional method
    unsigned gibbs_total_recomb; //count recomb events during gibbs for logging purposes
    unsigned cycle_ctr;          //which cycle is this
    
    unsigned (*lookup)(struct conf*c,struct marker*m1,struct marker*m2,unsigned x); //which rlookup func to use
    
    double (*map_func)(double); //which map distance function to use
};

//define a mutation event
struct mutation
{
    //segment mutation
    //take {src1,...src2} inclusive, if inv invert their order
    //move to {dst1,...dst2} inclusive
    int src1,src2;       //source segment
    int inv;             //invert flag
    int dst1,dst2;       //destination location
};
#endif
