#include "crosslink_group.h"
#include "crosslink_utils.h"
#include "rjvparser.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    struct map*mp=NULL;
    struct lg*p=NULL;
    struct earray*e=NULL;
    struct weights*w=NULL;
    unsigned i;
    char buff[BUFFER];
    char*weight_str=NULL;
   
    //parse command line options
    assert(c = calloc(1,sizeof(struct conf)));
    rjvparser("inp|STRING|!|input genotype file",&c->inp);
    rjvparser("outbase|STRING|-|basename for output genotype files",&c->outbase);
    rjvparser("mapbase|STRING|-|basename for output map files",&c->mapbase);
    rjvparser("redun|STRING|-|filename for outputting marker redundancy information",&c->redun);
    rjvparser("log|STRING|-|filename for outputting logging information",&c->log);
    rjvparser("prng_seed|UNSIGNED|0|random number generator seed, 0=use system time",&c->gg_prng_seed);
    rjvparser("map_func|UNSIGNED|1|mapping func, 1=Haldane,2=Kosambi",&c->gg_map_func);
    rjvparser("randomise_order|UNSIGNED|0|start from a random initial marker ordering",&c->gg_randomise_order);
    rjvparser("bitstrings|UNSIGNED|0|use bitstring data representation internally",&c->gg_bitstrings);
    rjvparser("matpat_lod|FLOAT|0.0|minimum LOD used to identify spurious linkage between maternal and paternal markers, 0.0=disable",&c->grp_matpat_lod);
    rjvparser("matpat_weights|STRING|01|conditional weightings to give markers when correcting marker typing errors\n\teg 01P03L05 gives default weight of 1 but 3 to markers starting with P and 5 for those starting with L",&weight_str);
    rjvparser("min_lod|FLOAT|3.0|minimum linkage LOD to use when forming linkage groups",&c->grp_min_lod);
    rjvparser("em_tol|FLOAT|1e-5|for 2 point rf calculations, convergence tolerance for EM algorithm",&c->grp_em_tol);
    rjvparser("em_maxit|UNSIGNED|100|for 2 point rf calculations, max EM iterations",&c->grp_em_maxit);
    rjvparser("knn|UNSIGNED|0|how many nearest neighbours to use for kNN missing data imputation, 0=disable imputation",&c->grp_knn);
    rjvparser("ignore_cxr|UNSIGNED|0|1=use cxr and rxc linkage during grouping",&c->grp_ignore_cxr);
    rjvparser("redundancy_lod|FLOAT|0.0|minimum linkage LOD to use when identifying redundant markers, 0.0=disable",&c->grp_redundancy_lod);
    rjvparser2(argc,argv,rjvparser(0,0),"form markers into linkage groups, phase, impute missing values, correct marker typing errors, perform approximate ordering");
    
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
    
    //decode the marker type weights for matpat type error correction
    w = decode_weights(weight_str);

    //open logfile
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
    p = generic_load_merged(c,c->inp,0,0);
    
    //treat as unphased
    generic_convert_to_unphased(c,p);
    
    //report what was loaded
    if(c->flog) fprintf(c->flog,"#loaded %u markers %u individuals from file %s\n",p->nmarkers,c->nind,c->inp);

    //shuffle markers into random order
    if(c->gg_randomise_order) randomise_order(p->nmarkers,p->array);

    //assign markers true position, defined by alphabetical sorting by name
    //if(c->gg_show_pearson) set_true_positions(p->nmarkers,p->array);
    
    //assign random uids not related to original file order or true position
    assign_uids(p->nmarkers,p->array);
    
    //calculate all-vs-all LOD values
    assert(e = calloc(1,sizeof(struct earray)));
    build_elist(c,p,e);
    
    //remove any markers marked as redundant by build_elist and associated edges 
    if(c->grp_redundancy_lod) remove_redundant_markers(c,p,e);
    
    //form linkage groups
    assert(mp = calloc(1,sizeof(struct map)));
    
    form_groups(c,p,e,mp);
    
    //phase markers per lg / parental origin
    //sets m->phase
    //impute missing values
    for(i=0; i<mp->nlgs; i++)
    {   
        //fix marker typing errors (ie switch LM <=> NP)
        if(c->grp_matpat_lod > 0.0) fix_marker_types(c,mp->lgs[i],mp->earrays[i],w);
        
        phase_markers(c,mp->lgs[i],mp->earrays[i],0);
        phase_markers(c,mp->lgs[i],mp->earrays[i],1);
        generic_apply_phasing(c,mp->lgs[i]);
        
        if(c->grp_knn > 0) impute_missing(c,mp->lgs[i],mp->earrays[i]);
    }
    
    //give markers approximate order
    for(i=0; i<mp->nlgs; i++)
    {
        distance_and_sort(c,mp->earrays[i]);            //calc edge map distances and sort, prioritise nonhk
        order_markers2(c,mp->lgs[i],mp->earrays[i],0);  //maternal ordering
        order_markers2(c,mp->lgs[i],mp->earrays[i],1);  //paternal ordering
        comb_map_positions2(c,mp->lgs[i],1);            //combine mat/pat info with flip check
    }
    
    //if processing test data check for phasing and ordering errors
    //if(c->flog && c->grp_check_phase) check_phase(c,mp);
    
    //calc pearson correlation wrt true marker order
    //if(c->flog && c->gg_show_pearson) show_pearson_all(c,mp);
    
    //save to file grouped by lg and sorted by approx order
    if(c->outbase != NULL)
    {
        for(i=0; i<mp->nlgs; i++)
        {
            sprintf(buff,"%s%s.loc",c->outbase,mp->lgs[i]->name);
            save_lg_markers(c,buff,mp->lgs[i]);
        }
    }
    
    //save approx map positions
    if(c->mapbase != NULL)
    {
        for(i=0; i<mp->nlgs; i++)
        {
            sprintf(buff,"%s%s.map",c->mapbase,mp->lgs[i]->name);
            save_lg_map(buff,mp->lgs[i]);
        }
    }
    
    /*close log file*/
    if(c->flog) fclose(c->flog);

    return 0;
}
