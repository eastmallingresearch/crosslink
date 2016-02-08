/*
sort LG frags into an order whereby frags with high linkage LOD
are adjacent
this helps when viewing the whole map in crosslink_viewer
as the interesting information appears close to the main diagonal
and can still be viewed when zoomed in

assumes fully phased and imputed data
checks for LM <=> NP linkage
*/

#include "gg_utils.h"
#include "gg_ga.h"
#include "gg_gibbs.h"
#include "rjv_cutils.h"

#include <stdlib.h>

int main(int argc,char*argv[])
{
    FILE*f=NULL;
    
    struct conf*c=NULL;
    double*maxlod=NULL;
    unsigned*order=NULL;
    unsigned*best=NULL;
    unsigned i,j,k,l,iters,retries,utmp,try;
    double best_score,new_score,final_score,minlod;
    
    srand48(time(NULL));
    srand(time(NULL)+1234);

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parsestr(argc,argv,"out",&c->out,0,NULL);
    parsedbl(argc,argv,"minlod",&minlod,1,1.0);
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,1);
    parseuns(argc,argv,"iters",&iters,1,5000);
    parseuns(argc,argv,"retries",&retries,1,5000);
    parseend(argc,argv);
    
    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load phased marker data from all lgs
    load_imputed_by_lg(c,c->inp);
    
    //perform all-versus-all marker comparison
    //retain only the highest lod per lg<=>lg pair
    maxlod = find_maxlod(c,minlod);
    
    assert(order = calloc(c->nlgs,sizeof(unsigned)));
    assert(best = calloc(c->nlgs,sizeof(unsigned)));
    
    //initial order is file order
    for(i=0; i<c->nlgs; i++) order[i] = i;
    final_score = -1.0;
    
    for(try=0; try<retries; try++)
    {
        //improve order by trial and error
        best_score = -1.0;
        for(i=0; i<iters; i++)
        {
            //find current score if not yet known
            if(best_score < 0.0)
            {
                best_score = 0.0;
                for(j=0; j<c->nlgs-1; j++) best_score += maxlod[(order[j])*c->nlgs+(order[j+1])];
                //printf("best score=%lf\n",best_score);
            }
            
            //choose a modification to the order
            if(drand48() < 0.5)
            {
                //swap adjacent lgs
                j = rand() % (c->nlgs-1);
                k = j + 1;
            }
            else
            {
                //swap any two lgs
                j = rand() % c->nlgs;
                k = rand() % c->nlgs;
            }
            
            SWAP(order[j],order[k],utmp);
            new_score = 0.0;
            for(l=0; l<c->nlgs-1; l++) new_score += maxlod[(order[l])*c->nlgs+(order[l+1])];
            
            if(new_score > best_score)
            {
                //accept new order
                best_score = new_score;
                //printf("%u: best score=%lf\n",i,best_score);
            }
            else
            {
                //revert to previous order
                SWAP(order[j],order[k],utmp);
            }
        }
        
        if(best_score > final_score)
        {
            final_score = best_score;
            for(j=0; j<c->nlgs; j++) best[j] = order[j];
            printf("final_score=%lf\n",final_score);
        }
        
        //shuffle order
        for(j=0; j<c->nlgs/4; j++)
        {
            k = rand() % c->nlgs;
            SWAP(order[j],order[k],utmp);
        }
    }
    
    printf("final_score=%lf\n",final_score);
    
    f = fopen(c->out,"wb");
    
    for(i=0; i<c->nlgs; i++)
    {
        j = best[i];
        print_order(c,c->lg_names[j],c->lg_nmarkers[j],c->lg_markers[j],f);
    }
    
    fclose(f);
    
    return 0;
}
