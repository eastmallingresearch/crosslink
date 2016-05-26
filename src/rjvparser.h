//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#ifndef __RJV_PARSER_H__
#define __RJV_PARSER_H__
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/*
    rjvparser("inp|STRING|!|name of input file",&inp);  // !=required
    rjvparser("out|STRING|-|name of output file",&out); // -=optional (no default)
    rjvparser("orig|STRING|ORIGINAL|name of original file",&orig); // with default value
    rjvparser("size|INTEGER|-|number of items",&size);// no default value provided
    rjvparser("iters|UNSIGNED|-|number of items",&size);// no default value provided
    rjvparser("density|FLOAT|1.0|item density",&density);
    rjvparser2(argc,argv,rjvparser(0,0),"this is the main doc string");
*/

struct myop
{
    const char*name; //option name
    const char*type; //option type
    const char*def;  //default
    const char*doc;  //help text
    void*pvar;       //pointer to variable
    struct myop*next;
    unsigned assigned; //0=unassigned 1=assigned
};

void rjvparser_help(struct myop*head,char*doc);
void rjvparser2(int argc,char**argv,struct myop*head,char*doc);
struct myop*rjvparser(const char*str,void*pvar);
#endif

