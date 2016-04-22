#include "rjv_cutils.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>

/*
print error message to stderr then return error code
*/
/*void rjverr(const char*message)
{
    fprintf(stderr,message);
    abort();
    //exit(1);
}*/

/*
get system time with microsecond resolution
useful for ensuring a program gets a unique PRNG seed
should really use /dev/urandom as well
*/
long int get_time()
{
    struct timeval tv;
    gettimeofday(&tv,NULL);
    //return tv.tv_sec * 1000 + tv.tv_usec / 1000; //milliseconds
    return tv.tv_sec * 1000000 + tv.tv_usec; //microseconds
}

/*quit if help option found*/
void parseend(int argc,char*argv[])
{
    int i;
    
    for(i=1; i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0)
        {
            exit(0);
        }
    }
}

void parseint(int argc,char*argv[],const char*name,int*p,unsigned hasdef,int defval)
{
    int i,res;
    
    for(i=1; i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0)
        {
            /*print help info*/
            printf("--%s <int>",name);
            if(hasdef) printf(" (DEFAULT:%d)",defval);
            printf("\n");
            return; 
        }
    }
    
    for(i=1; i<argc; i++)
    {
        /*is this the named argument*/
        if(strlen(argv[i]) < 3) continue;
        if(argv[i][0] != '-' || argv[i][1] != '-' || strcmp(argv[i]+2,name) != 0) continue;
        
        /*check at least one additional token exists*/
        if(i == argc-1)
        {
            printf("option %s value missing\n",name);
            exit(1);
        }
        
        /*parse the value*/
        res = sscanf(argv[i+1],"%d",p);
        if(res != 1)
        {
            printf("option %s failed to parse value\n",name);
            exit(1);
        }

        /*assign the first argument we encounter, ignore any extra ones*/
        break;
    }
    
    /*no option found, assign default*/
    if(i == argc)
    {
        if(hasdef)
        {
            *p = defval;
        }
        else
        {
            printf("option %s is required\n",name);
            exit(1);
        }
    }
}

void parsedbl(int argc,char*argv[],const char*name,double*p,unsigned hasdef,double defval)
{
    int i,res;
    
    for(i=1; i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0)
        {
            /*print help info*/
            printf("--%s <double>",name);
            if(hasdef) printf(" (DEFAULT:%f)",defval);
            printf("\n");
            return; 
        }
    }
    
    for(i=1; i<argc; i++)
    {
        /*is this the named argument*/
        if(strlen(argv[i]) < 3) continue;
        if(argv[i][0] != '-' || argv[i][1] != '-' || strcmp(argv[i]+2,name) != 0) continue;
        
        /*check at least one additional token exists*/
        if(i == argc-1)
        {
            printf("option %s value missing\n",name);
            exit(1);
        }
        
        /*parse the value*/
        res = sscanf(argv[i+1],"%lf",p);
        if(res != 1)
        {
            printf("option %s failed to parse value\n",name);
            exit(1);
        }

        /*assign the first argument we encounter, ignore any extra ones*/
        break;
    }
    
    /*no option found, assign default*/
    if(i == argc)
    {
        if(hasdef)
        {
            *p = defval;
        }
        else
        {
            printf("option %s is required\n",name);
            exit(1);
        }
    }
}

void parseuns(int argc,char*argv[],const char*name,unsigned*p,unsigned hasdef,unsigned defval)
{
    int i,res;
    
    for(i=1; i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0)
        {
            /*print help info*/
            printf("--%s <unsigned int>",name);
            if(hasdef) printf(" (DEFAULT:%u)",defval);
            printf("\n");
            return; 
        }
    }
    
    for(i=1; i<argc; i++)
    {
        /*is this the named argument*/
        if(strlen(argv[i]) < 3) continue;
        if(argv[i][0] != '-' || argv[i][1] != '-' || strcmp(argv[i]+2,name) != 0) continue;
        
        /*check at least one additional token exists*/
        if(i == argc-1)
        {
            printf("option %s value missing\n",name);
            exit(1);
        }
        
        /*parse the value*/
        res = sscanf(argv[i+1],"%u",p);
        if(res != 1)
        {
            printf("option %s failed to parse value\n",name);
            exit(1);
        }

        /*assign the first argument we encounter, ignore any extra ones*/
        break;
    }
    
    /*no option found, assign default*/
    if(i == argc)
    {
        if(hasdef)
        {
            *p = defval;
        }
        else
        {
            printf("option %s is required\n",name);
            exit(1);
        }
    }
}

void parsestr(int argc,char*argv[],const char*name,char**p,unsigned hasdef,const char*defval)
{
    int i,res,slen;
    
    for(i=1; i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0)
        {
            /*print help info*/
            printf("--%s <str>",name);
            if(hasdef) printf(" (DEFAULT:%s)",defval);
            printf("\n");
            return; 
        }
    }

    for(i=1; i<argc; i++)
    {
        /*is this the named argument*/
        if(strlen(argv[i]) < 3) continue;
        if(argv[i][0] != '-' || argv[i][1] != '-' || strcmp(argv[i]+2,name) != 0) continue;
        
        /*check at least one additional token exists*/
        if(i == argc-1)
        {
            printf("option %s value missing\n",name);
            exit(1);
        }
        
        /*test the option's length*/
        slen = strlen(argv[i+1]);
        if(slen > 5000)
        {
            printf("option %s value too long\n",name);
            exit(1);
        }
        
        /*allocate memory*/
        *p = calloc(slen+1,sizeof(char));
        if(*p == NULL)
        {
            printf("option %s memory error\n",name);
            exit(1);
        }
        
        /*parse the value*/
        res = sscanf(argv[i+1],"%s",*p);
        if(res != 1)
        {
            printf("option %s failed to parse value\n",name);
            exit(1);
        }

        /*assign the first argument we encounter, ignore any extra ones*/
        break;
    }
    
    /*no option found, assign default*/
    if(i == argc)
    {
        if(hasdef)
        {
            /*test the option's length*/
            slen = strlen(defval);
            if(slen > 5000)
            {
                printf("option %s value too long\n",name);
                exit(1);
            }
            
            /*allocate memory*/
            *p = calloc(slen+1,sizeof(char));
            if(*p == NULL)
            {
                printf("option %s memory error\n",name);
                exit(1);
            }
            
            /*parse the value*/
            res = sscanf(defval,"%s",*p);
            if(res != 1)
            {
                printf("option %s failed to parse value\n",name);
                exit(1);
            }
        }
        else
        {
            printf("option %s is required\n",name);
            exit(1);
        }
    }
}
