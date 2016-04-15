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
#include "rjvparser.h"
// #include "rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct lg*p=NULL;
    unsigned i;
    FILE*f;
    struct conf*c=NULL;
   
    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    
    rjvparser("inp|STRING|!|input genotype file",&c->inp);
    rjvparser("out|STRING|-|output genotype file",&c->out);
    rjvparser("log|STRING|-|output log file",&c->log);
    rjvparser("map|STRING|-|output map file",&c->map);
    rjvparser("mstmap|STRING|-|output mstmap file",&c->mstmap);
    
    rjvparser("seed|UNSIGNED|1|random number generator seed, 0=use system time",&c->gg_prng_seed);
    rjvparser("map_func|UNSIGNED|1|mapping func, 1=Haldane,2=Kosambi",&c->gg_map_func);
    rjvparser("randomise_order|UNSIGNED|0|start from a random initial marker ordering",&c->gg_randomise_order);
    rjvparser("bitstrings|UNSIGNED|1|use bitstring data representation internally",&c->gg_bitstrings);
    rjvparser("show_pearson|UNSIGNED|0|log Pearson correlation of ordering information",&c->gg_show_pearson);
    rjvparser("show_hkcheck|UNSIGNED|0|log hk imputation information",&c->gg_show_hkcheck);
    rjvparser("show_width|UNSIGNED|9999999|width of debug output",&c->gg_show_width);
    rjvparser("show_height|UNSIGNED|9999999|height of debug output",&c->gg_show_height);
    rjvparser("show_counters|UNSIGNED|0|log Gibbs imputation information",&c->gg_show_counters);
    rjvparser("show_initial|UNSIGNED|0|show initial state",&c->gg_show_initial);
    rjvparser("show_bits|UNSIGNED|0|show bit states",&c->gg_show_bits);
    rjvparser("pause|UNSIGNED|0|pause each iteration",&c->gg_pause);
    
    rjvparser("homeo_minlod|FLOAT|1.0|detect cross homeolog markers, minlod",&c->gg_homeo_minlod);
    rjvparser("homeo_maxlod|FLOAT|16.0|detect cross homeolog markers, maxlod",&c->gg_homeo_maxlod);
    rjvparser("homeo_mincount|UNSIGNED|0|report as possible cross homeolog if implicated more than this many time, 0 to disable",&c->gg_homeo_mincount);
    
    rjvparser("ga_gibbs_cycles|UNSIGNED|10|number of GA-Gibbs cycles",&c->ga_gibbs_cycles);
    rjvparser("ga_report|UNSIGNED|0|GA log reporting period, 0=disabled",&c->ga_report);
    rjvparser("ga_iters|UNSIGNED|100000|number of GA iterations per GA-Gibbs cycle",&c->ga_iters);
    rjvparser("ga_use_mst|UNSIGNED|0|how many GA-Gibbs cycles to perform initial MST ordering before the GA (0=none,N=up to and including the Nth cycle)",&c->ga_use_mst);
    rjvparser("ga_minlod|FLOAT|3.0|min LOD for MST construction and global order optimisation scoring",&c->ga_minlod);
    rjvparser("ga_mst_nonhk|UNSIGNED|1|prioritise non-hk linkage when building the MST",&c->ga_mst_nonhk);
    rjvparser("ga_optimise_meth|UNSIGNED|0|0=optimse map total recombination events, 1=optimise total map distance, 2=optimise a global measure of map quality (sets --ga_skip_order1=1 --randomise_order=0)",&c->ga_optimise_meth);
    rjvparser("ga_prob_hop|FLOAT|0.333|probability a mutation moves a single marker",&c->ga_prob_hop);
    rjvparser("ga_max_hop|FLOAT|0.1|max distance a single marker can move as proportion of whole linkage group",&c->ga_max_hop);
    rjvparser("ga_prob_move|FLOAT|0.333|probability a mutation moves a block of multiple markers",&c->ga_prob_move);
    rjvparser("ga_max_mvseg|FLOAT|0.1|max number of markers in the block as proportion of whole linkage group",&c->ga_max_mvseg);
    rjvparser("ga_max_mvdist|FLOAT|0.1|max distance the block of markers can move as proportion of whole linkage group",&c->ga_max_mvdist);
    rjvparser("ga_prob_inv|FLOAT|0.5|probability the block of markers also inverts as well as moves",&c->ga_prob_inv);
    rjvparser("ga_max_seg|FLOAT|0.1|for in-place inversion mutations, max number of markers to be inverted as proportion of whole linkage group",&c->ga_max_seg);
    rjvparser("ga_cache|UNSIGNED|1|1=use cache of rf values in GA",&c->ga_cache);
    rjvparser("ga_em_tol|FLOAT|1e-5|for 2 point rf calculations, convergence tolerance for EM algorithm",&c->ga_em_tol);
    rjvparser("ga_em_maxit|UNSIGNED|100|for 2 point rf calculations, max EM iterations",&c->ga_em_maxit);
    rjvparser("ga_skip_order1|UNSIGNED|0|1=skip first GA ordering, go straight to Gibbs using the marker order from the input file",&c->ga_skip_order1);
    
    rjvparser("gibbs_samples|UNSIGNED|500|number of Gibbs samples to collect per GA-Gibbs cycle",&c->gibbs_samples);
    rjvparser("gibbs_burnin|UNSIGNED|20|Gibbs burn in cycles",&c->gibbs_burnin);
    rjvparser("gibbs_period|UNSIGNED|1|Gibbs cycles per sample",&c->gibbs_period);
    rjvparser("gibbs_report|UNSIGNED|0|Gibbs log reporting period, 0=disabled",&c->gibbs_report);
    rjvparser("gibbs_prob_sequential|FLOAT|0.333|probability Gibbs cycle uses sequential mode",&c->gibbs_prob_sequential);
    rjvparser("gibbs_prob_unidir|FLOAT|0.333|probability Gibbs cycle uses unidirectional mode",&c->gibbs_prob_unidir);
    rjvparser("gibbs_min_prob_1|FLOAT|0.1|minimum permitted probability of a state transition at the start of burn in period",&c->gibbs_min_prob_1);
    rjvparser("gibbs_min_prob_2|FLOAT|0.0|minimum permitted probability of a state transition by the end of burn in period",&c->gibbs_min_prob_2);
    rjvparser("gibbs_twopt_1|FLOAT|0.1|weighting given to two point rf at start of burn in period",&c->gibbs_twopt_1);
    rjvparser("gibbs_twopt_2|FLOAT|0.0|weighting given to two point rf by the end of burn in period",&c->gibbs_twopt_2);
    rjvparser("gibbs_min_ctr|UNSIGNED|0|minimum sample counter value to trigger imputation of the state, 0=always impute",&c->gibbs_min_ctr);
    
    rjvparser2(argc,argv,rjvparser(0,0),"make final map ordering, impute missing hk information");
    
    //seed random number generator
    if(c->gg_prng_seed != 0)
    {
        srand(c->gg_prng_seed);
    }
    else
    {
        struct timeval tv;
        gettimeofday(&tv,NULL);
        srand(tv.tv_sec * 1000000 + tv.tv_usec);
    }
    srand48(rand());
    
    //global optimsation currently requires partially ordered markers as input
    if(c->ga_optimise_meth == 2)
    {
        c->ga_skip_order1 = 1;
        c->gg_randomise_order = 0;
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
    if(c->log != NULL)
    {
        c->flog = fopen(c->log,"wb");
        if(c->flog == NULL)
        {
            printf("unable to open logfile %s for output\n",c->log);
            exit(1);
        }
    }

    //load all data from file, treat as a single lg
    //p = generic_load_merged(c,c->inp,0,0);
    p = noheader_lg(c,c->inp);
    
    //treat as phased
    generic_convert_to_phased(c,p);
    
    //crosslink_map is not yet refactored to use struct lg
    c->nmarkers = p->nmarkers;
    c->array = p->array;

    //edge list will be expanded as required
    c->nedgemax = 10000;
    assert(c->elist = calloc(c->nedgemax,sizeof(struct edge*)));
    assert(c->mutant = calloc(c->nmarkers,sizeof(struct marker*)));

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
    
    if(c->gg_bitstrings) compress_to_bitstrings(c,c->nmarkers,c->array);
    
    if(c->map != NULL)
    {
        //produce maternal and paternal map positions from the current ordering
        indiv_map_positions(c,c->array,0);
        indiv_map_positions(c,c->array,1);
        
        //produce combined map positions
        comb_map_positions(c,c->nmarkers,c->array,0,0);
    }
    
    //output final marker ordering
    if(c->out != NULL)
    {
        if(c->flog) fprintf(c->flog,"#saving marker data and ordering to %s\n",c->out);
        
        f = fopen(c->out,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->out);
            exit(1);
        }
        print_order(c,c->nmarkers,c->array,f);
        fclose(f);
    }

    //output final map positions
    if(c->map != NULL)
    {
        if(c->flog) fprintf(c->flog,"#saving map positions to %s\n",c->map);
        
        f = fopen(c->map,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->map);
            exit(1);
        }

        print_map(c->nmarkers,c->array,f,0,p->name);
        fclose(f);
    }

    if(c->log != NULL) fclose(c->flog);

    return 0;
}
