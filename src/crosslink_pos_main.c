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


/*
build using make.sh script

calc map positions only without reordering or imputing hks
*/

#include "crosslink_utils.h"
#include "crosslink_ga.h"
#include "crosslink_gibbs.h"
#include "rjvparser.h"

int main(int argc,char*argv[])
{
    struct lg*p=NULL;
    FILE*f;
    struct conf*c=NULL;
   
    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    
    rjvparser("inp|STRING|!|name of input genotype file",&c->inp);
    rjvparser("out|STRING|-|name of output map file",&c->out);
    
    rjvparser("seed|UNSIGNED|1|random number generator seed, 0=use system time",&c->gg_prng_seed);
    rjvparser("map_func|UNSIGNED|1|mapping func, 1=Haldane,2=Kosambi",&c->gg_map_func);
    rjvparser("bitstrings|UNSIGNED|1|use bitstring data representation internally",&c->gg_bitstrings);
    
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\ncalculate map positions");
    
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
    
    //load all data from file, treat as a single lg
    //p = generic_load_merged(c,c->inp,0,0);
    p = noheader_lg(c,c->inp);
    
    //treat as phased
    generic_convert_to_imputed(c,p);
    
    //crosslink_map is not yet refactored to use struct lg
    c->nmarkers = p->nmarkers;
    c->array = p->array;

    //assign uids not related to original file order
    assign_uids(c->nmarkers,c->array);
    
    //produce maternal and paternal map positions from the current ordering
    indiv_map_positions(c,c->array,0);
    indiv_map_positions(c,c->array,1);
    
    //produce combined map positions
    comb_map_positions(c,c->nmarkers,c->array,0,0);
    
    //output final map positions
    if(c->out != NULL)
    {
        f = fopen(c->out,"wb");
        if(f == NULL)
        {
            printf("unable to open file %s for output\n",c->out);
            exit(1);
        }

        print_map(c->nmarkers,c->array,f,0,p->name);
        fclose(f);
    }

    return 0;
}
