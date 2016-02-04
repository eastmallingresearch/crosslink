#include "gg_group.h"
#include "gg_utils.h"
#include "rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    struct map*mp=NULL;
    struct lg*p=NULL;
    struct earray*e=NULL;
    unsigned i;
    char buff[BUFFER];
   
    //parse command line options
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parsestr(argc,argv,"outbase",&c->outbase,1,"NONE");
    parsestr(argc,argv,"mapbase",&c->mapbase,1,"NONE");
    parsestr(argc,argv,"log",&c->log,1,"NONE");
    parseuns(argc,argv,"prng_seed",&c->gg_prng_seed,1,0);
    parseuns(argc,argv,"map_func",&c->gg_map_func,1,1);
    parseuns(argc,argv,"randomise_order",&c->gg_randomise_order,1,0);
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,0);
    parseuns(argc,argv,"show_pearson",&c->gg_show_pearson,1,0);
    parseuns(argc,argv,"detect_matpat_linkage",&c->grp_detect_matpat,1,0);
    parseuns(argc,argv,"fix_marker_type",&c->grp_fix_type,1,0);
    parseuns(argc,argv,"check_phase",&c->grp_check_phase,1,0);
    parsedbl(argc,argv,"min_lod",&c->grp_min_lod,1,3.0);
    parsedbl(argc,argv,"em_tol",&c->grp_em_tol,1,1e-5);
    parseuns(argc,argv,"em_maxit",&c->grp_em_maxit,1,100);
    parseuns(argc,argv,"min_lgs",&c->grp_min_lgs,1,1);
    parseuns(argc,argv,"knn",&c->grp_knn,1,5);
    parseend(argc,argv);
    
    //seed random number generator(s)
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

    //open logfile
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
    
    //treat as unphased
    generic_convert_to_unphased(c,p);
    
    //report what was loaded
    if(c->flog) fprintf(c->flog,"#loaded %u markers %u individuals from file %s\n",p->nmarkers,c->nind,c->inp);

    //shuffle markers into random order
    if(c->gg_randomise_order) randomise_order(p->nmarkers,p->array);

    //assign markers true position, defined by alphabetical sorting by name
    if(c->gg_show_pearson) set_true_positions(p->nmarkers,p->array);
    
    //assign random uids not related to original file order or true position
    assign_uids(p->nmarkers,p->array);
    
    //calculate all-vs-all LOD values
    assert(e = calloc(1,sizeof(struct earray)));
    build_elist(c,p,e);
    
    //sort by LOD
    sort_elist(e);
    
    //form linkage groups
    assert(mp = calloc(1,sizeof(struct map)));
    form_groups(c,p,e,mp);
    
    //phase markers per lg / parental origin
    //sets m->phase
    //impute missing values
    for(i=0; i<mp->nlgs; i++)
    {   
        //fix marker typing errors (ie switch LM <=> NP)
        if(c->grp_detect_matpat && c->grp_fix_type) fix_marker_types(c,mp->lgs[i],mp->earrays[i]);
        
        phase_markers(c,mp->lgs[i],mp->earrays[i],0);
        phase_markers(c,mp->lgs[i],mp->earrays[i],1);
        
        if(c->grp_knn > 0) impute_missing(c,mp->lgs[i],mp->earrays[i]);
    }
    
    //give markers approximate order
    for(i=0; i<mp->nlgs; i++)
    {
        sort_by_dist(c,mp->earrays[i]);    //calc edge map distances and sort
        order_markers2(c,mp->lgs[i],mp->earrays[i],0);  //maternal ordering
        order_markers2(c,mp->lgs[i],mp->earrays[i],1);  //paternal ordering
        comb_map_positions2(c,mp->lgs[i],1);   //combine mat/pat info with flip check
    }
    
    //if processing test data with known phase, check for phasing errors
    if(c->flog && c->grp_check_phase) check_phase(c,mp);
    
    //calc pearson correlation wrt true marker order
    if(c->flog && c->gg_show_pearson) show_pearson_all(c,mp);
    
    //save to file grouped by lg and sorted by approx order
    if(strcmp(c->outbase,"NONE") != 0)
    {
        for(i=0; i<mp->nlgs; i++)
        {
            sprintf(buff,"%s%s.loc",c->outbase,mp->lgs[i]->name);
            save_lg_markers(c,buff,mp->lgs[i]);
        }
    }
    
    //save approx map positions
    if(strcmp(c->mapbase,"NONE") != 0)
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
