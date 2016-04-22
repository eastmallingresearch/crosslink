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

#include "sample_map.h"

#ifndef NDEBUG

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    
    c = init_conf(argc,argv);
    
    load_map(c);
    
    sample_map(c);
    
    //output each linkage group to a separate file
    //output original, error free marker data
    if(c->orig != NULL) save_data(c,c->orig,1);

    if(c->prob_missing+c->prob_error > 0.0) apply_errors(c);
    
    random_order(c);

    //save marker data into a single file, with errors
    save_data(c,c->out,0);
    
    return 0;
}

#endif
