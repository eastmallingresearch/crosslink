/*
build using make.sh script

genetic map ordering for outbred population having only hk,lm and np type markers
(using joinmap naming conventions)

this program only deals with one linkage group at a time
all missing data must imputed first

also runs gibbs sampler to impute inheritance vectors for hk/kh genotypes
*/

#include "crosslink_utils.h"
#include "crosslink_ga.h"
#include "crosslink_gibbs.h"
#include "rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct lg*p=NULL;
    unsigned i;
    FILE*f;
    struct conf*c=NULL;
   
    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parsestr(argc,argv,"out",&c->out,1,"NONE");
    parsestr(argc,argv,"lg",&c->lg,1,"NONE");
    parsestr(argc,argv,"log",&c->log,1,"NONE");
    parsestr(argc,argv,"map",&c->map,1,"NONE");
    parsestr(argc,argv,"mstmap",&c->mstmap,1,"NONE");
    
    parseuns(argc,argv,"prng_seed",&c->gg_prng_seed,1,0);
    parseuns(argc,argv,"map_func",&c->gg_map_func,1,1);
    parseuns(argc,argv,"randomise_order",&c->gg_randomise_order,1,0);
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,0);
    parseuns(argc,argv,"show_pearson",&c->gg_show_pearson,1,0);
    parseuns(argc,argv,"show_hkcheck",&c->gg_show_hkcheck,1,0);
    parseuns(argc,argv,"show_width",&c->gg_show_width,1,9999999);
    parseuns(argc,argv,"show_height",&c->gg_show_height,1,9999999);
    parseuns(argc,argv,"show_counters",&c->gg_show_counters,1,0);
    parseuns(argc,argv,"show_initial",&c->gg_show_initial,1,0);
    parseuns(argc,argv,"show_bits",&c->gg_show_bits,1,0);
    parseuns(argc,argv,"pause",&c->gg_pause,1,0);
    
    parseuns(argc,argv,"ga_gibbs_cycles",&c->ga_gibbs_cycles,1,10);
    parseuns(argc,argv,"ga_report",&c->ga_report,1,0);
    parseuns(argc,argv,"ga_iters",&c->ga_iters,1,10000);
    parseuns(argc,argv,"ga_use_mst",&c->ga_use_mst,1,0);
    parsedbl(argc,argv,"ga_mst_minlod",&c->ga_mst_minlod,1,3.0);
    parseuns(argc,argv,"ga_mst_nonhk",&c->ga_mst_nonhk,1,1);
    parseuns(argc,argv,"ga_optimise_dist",&c->ga_optimise_dist,1,0);
    parsedbl(argc,argv,"ga_prob_hop",&c->ga_prob_hop,1,0.5);
    parsedbl(argc,argv,"ga_max_hop",&c->ga_max_hop,1,0.1);
    parsedbl(argc,argv,"ga_prob_move",&c->ga_prob_move,1,0.5);
    parsedbl(argc,argv,"ga_max_mvseg",&c->ga_max_mvseg,1,0.05);
    parsedbl(argc,argv,"ga_max_mvdist",&c->ga_max_mvdist,1,0.05);
    parsedbl(argc,argv,"ga_prob_inv",&c->ga_prob_inv,1,0.5);
    parsedbl(argc,argv,"ga_max_seg",&c->ga_max_seg,1,0.05);
    parseuns(argc,argv,"ga_cache",&c->ga_cache,1,1);
    parsedbl(argc,argv,"ga_em_tol",&c->ga_em_tol,1,1e-5);
    parseuns(argc,argv,"ga_em_maxit",&c->ga_em_maxit,1,100);
    parseuns(argc,argv,"ga_skip_order1",&c->ga_skip_order1,1,0);
    
    parseuns(argc,argv,"gibbs_samples",&c->gibbs_samples,1,10000);
    parseuns(argc,argv,"gibbs_burnin",&c->gibbs_burnin,1,1000);
    parseuns(argc,argv,"gibbs_period",&c->gibbs_period,1,1000);
    parseuns(argc,argv,"gibbs_report",&c->gibbs_report,1,0);
    parsedbl(argc,argv,"gibbs_prob_sequential",&c->gibbs_prob_sequential,1,0.5);
    parsedbl(argc,argv,"gibbs_prob_unidir",&c->gibbs_prob_unidir,1,0.5);
    parsedbl(argc,argv,"gibbs_min_prob_1",&c->gibbs_min_prob_1,1,0.0);
    parsedbl(argc,argv,"gibbs_min_prob_2",&c->gibbs_min_prob_2,1,0.0);
    parsedbl(argc,argv,"gibbs_twopt_1",&c->gibbs_twopt_1,1,0.0);
    parsedbl(argc,argv,"gibbs_twopt_2",&c->gibbs_twopt_2,1,0.0);
    parseuns(argc,argv,"gibbs_min_ctr",&c->gibbs_min_ctr,1,0);
    
    parseend(argc,argv);
    
    /*seed random number generator(s)*/
    if(c->gg_prng_seed == 0)
    {
        srand48(get_time());
        srand(get_time()+1234);
    }
    else
    {
        srand48(c->gg_prng_seed);
        srand(c->gg_prng_seed+1234);
    }
    
    //set up genetic mapping function
    switch(c->gg_map_func)
    {
        case 1:
            c->map_func = haldane;
            break;
        case 2:
            c->map_func = kosambi;
            break;
        default:
            assert(0);
    }
    
    //precalc bitmasks for every possible bit position
    init_masks(c);
    
    /*open logfile*/
    if(strcmp(c->log,"NONE") != 0)
    {
        c->flog = fopen(c->log,"wb");
        if(c->flog == NULL)
        {
            printf("unable to open logfile %s for output\n",c->log);
            exit(1);
        }
    }

    //load all data from file, treat as a single lg
    p = generic_load_merged(c,c->inp,0,0);
    
    //treat as phased
    generic_convert_to_phased(c,p);
    
    //crosslink_map is not yet refactored to use struct lg
    c->nmarkers = p->nmarkers;
    c->array = p->array;

    //edge list will be expanded as required
    c->nedgemax = 10000;
    assert(c->elist = calloc(c->nedgemax,sizeof(struct edge*)));
    assert(c->mutant = calloc(c->nmarkers,sizeof(struct marker*)));

    //load phased marker data from the requested lg only
    //load_phased_lg(c,c->inp,c->lg);
    
    //report what data was loaded
    if(c->flog) fprintf(c->flog,"#loaded %u markers %u individuals from file %s\n",c->nmarkers,c->nind,c->inp);
    
    //allocate data structures for imputing hk genotypes
    alloc_hks(c);

    //assign uids not related to original file order
    assign_uids(c->nmarkers,c->array);
    
    //find true marker positions, defined as alphabetical order
    if(c->gg_show_pearson) set_true_positions(c->nmarkers,c->array);
    
    if(c->gg_show_initial)
    {
        if(c->flog) fprintf(c->flog,"#dumping initial state to stdout\n");
        print_bits(c,c->array,0);
    }
    
    //shuffle marker order
    if(c->gg_randomise_order)
    {
        if(c->flog) fprintf(c->flog,"#randomising initial marker order\n");
        randomise_order(c->nmarkers,c->array);
    }
    
    //only alloc distance cache if option activated
    if(c->ga_cache) alloc_distance_cache(c);
    
    for(i=0; i<c->ga_gibbs_cycles; i++)
    {
        c->cycle_ctr = i;

        if(c->flog) fprintf(c->flog,"#starting ga-gibbs cycle %u / %u\n",i+1,c->ga_gibbs_cycles);
        
        /*order markers using the genetic algorithm*/
        order_map(c);
        
        if(c->flog) fflush(c->flog);

        /*impute inheritance vectors for hk/kh genotypes*/
        gibbs_impute(c);
        
        if(c->flog) fflush(c->flog);
    }
    
    //produce maternal and paternal map positions from the current ordering
    indiv_map_positions(c,c->array,0);
    indiv_map_positions(c,c->array,1);
    
    //produce combined map positions
    comb_map_positions(c,c->nmarkers,c->array,0,0);
    
    //output final marker ordering
    if(strcmp(c->out,"NONE") != 0)
    {
        if(c->flog) fprintf(c->flog,"#saving marker data and ordering to %s\n",c->out);
        
        f = fopen(c->out,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->out);
            exit(1);
        }
        print_order(c,c->lg,c->nmarkers,c->array,f);
        fclose(f);
    }

    //output final map positions
    if(strcmp(c->map,"NONE") != 0)
    {
        if(c->flog) fprintf(c->flog,"#saving map positions to %s\n",c->map);
        
        f = fopen(c->map,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->map);
            exit(1);
        }

        print_map(c->nmarkers,c->array,f,0,c->lg);
        fclose(f);
    }

    if(strcmp(c->log,"NONE") != 0) fclose(c->flog);

    return 0;
}
