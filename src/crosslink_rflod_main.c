/*
Crosslink
Copyright (C) 2016  NIAB EMR

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

contact:
robert.vickerstaff@emr.ac.uk
Robert Vickerstaff
NIAB EMR
New Road
East Malling
WEST MALLING
ME19 6BJ
United Kingdom
*/

#include "crosslink_group.h"
#include "crosslink_utils.h"
#include "rjvparser.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    struct lg*p=NULL;
    struct earray*e=NULL;
    unsigned i;
   
    //parse command line options
    assert(c = calloc(1,sizeof(struct conf)));
    rjvparser("inp|STRING|!|input genotype file",&c->inp);
    rjvparser("out|STRING|!|output rf LOD file",&c->out);
    rjvparser("log|STRING|-|filename for outputting logging information",&c->log);
    rjvparser("seed|UNSIGNED|1|random number generator seed, 0=use system time",&c->gg_prng_seed);
    rjvparser("bitstrings|UNSIGNED|1|use bitstring data representation internally",&c->gg_bitstrings);
    rjvparser("min_lod|FLOAT|3.0|minimum linkage LOD to use when forming linkage groups",&c->grp_min_lod);
    rjvparser("matpat_lod|FLOAT|0.0|minimum LOD used to identify spurious linkage between maternal and paternal markers, 0.0=disable",&c->grp_matpat_lod);
    rjvparser("em_tol|FLOAT|1e-5|for 2 point rf calculations, convergence tolerance for EM algorithm",&c->grp_em_tol);
    rjvparser("em_maxit|UNSIGNED|100|for 2 point rf calculations, max EM iterations",&c->grp_em_maxit);
    rjvparser("ignore_cxr|UNSIGNED|0|1=ignore cxr and rxc linkage during grouping",&c->grp_ignore_cxr);
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\nestimate two point rf and LOD values on phased marker data, output to file");
    
    c->gg_map_func=1;
    c->gg_randomise_order=0;
    //c->grp_matpat_lod=0.0;
    c->grp_knn=0;
    c->grp_redundancy_lod=0.0;
    
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
    
    //precalc bitmasks for every possible bit position
    init_masks(c);
    
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
    //p = generic_load_merged(c,c->inp,0,0);
    p = noheader_lg(c,c->inp);
    
    //treat as phased
    generic_convert_to_phased(c,p);
    
    //report what was loaded
    if(c->flog) fprintf(c->flog,"#loaded %u markers %u individuals from file %s\n",p->nmarkers,c->nind,c->inp);

    //assign random uids not related to original file order or true position
    assign_uids(p->nmarkers,p->array);
    
    //calculate all-vs-all LOD values
    assert(e = calloc(1,sizeof(struct earray)));
    build_elist(c,p,e);
    
    //dump rf lod info to file
    FILE*f=fopen(c->out,"wb");
    struct edge*q=NULL;

    for(i=0; i<e->nedges; i++)
    {
        q = e->array[i];
        fprintf(f,"%s %d %s %d %.17e %.17e\n",q->m1->name,q->m1->type,q->m2->name,q->m2->type,q->rf,q->lod);
    }
    fclose(f);
   
    /*close log file*/
    if(c->flog) fclose(c->flog);

    return 0;
}
