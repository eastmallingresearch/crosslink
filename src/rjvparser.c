//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#include "rjvparser.h"

struct myop*rjvparser(const char*str,void*pvar)
{
    static struct myop*head=NULL;
    static struct myop*prev=NULL;
    struct myop*p=NULL;
    char*pch=NULL;
    char*str2=NULL;
    char*tok[4];
    char*newdoc=NULL;
    char**ppvar=NULL;
    unsigned i;
    
    //return list of args
    if(str == NULL) return head;
    
    //alloc space for a new arg
    assert(p = calloc(1,sizeof(struct myop)));
    if(head == NULL) head = p;
    else             prev->next = p;
    prev = p;
    
    //make copy of str
    assert(str2 = calloc(strlen(str)+1,sizeof(char)));
    strcpy(str2,str);

    //split input up into four substrings
    i=0;
    while(1)
    {
        tok[i] = str2;
        pch = strchr(str2,'|');
        if(pch == NULL) break;
        *pch = '\0';
        str2 = pch + 1;
        i += 1;
    }
    
    assert(i == 3);
    
    p->name = tok[0];
    p->type = tok[1];
    p->def = tok[2];
    p->doc = tok[3];
    p->pvar = pvar;
    p->assigned = 0;
    
    //if default value present, parse it now
    if(p->def[0] != '-' && p->def[0] != '!')
    {
        switch(p->type[0])
        {
            case 'S': //STRING
                ppvar = (char**)p->pvar;
                assert(*ppvar = calloc(strlen(p->def)+1,sizeof(char))); //alloc space for default value
                strcpy(*ppvar,p->def);
                break;
            case 'I': //INTEGER
                assert(sscanf(p->def,"%d",(int*)p->pvar) == 1);
                break;
            case 'U': //UNSIGNED
                assert(sscanf(p->def,"%u",(unsigned*)p->pvar) == 1);
                break;
            case 'F': //FLOAT
                assert(sscanf(p->def,"%lf",(double*)p->pvar) == 1);
                break;
            default:
                assert(0);
        }
        
        p->assigned = 1;
    }
    else
    {
        if(p->type[0] == 'S')
        {
            ppvar = (char**)p->pvar;
            *ppvar = NULL; //ensure unassigned string is NULL
        }
    }
    
    //include default value information in doc string
    assert(newdoc = calloc(strlen(p->doc)+strlen(p->def)+15,sizeof(char)));
    switch(p->def[0])
    {
        case '-':
            strcpy(newdoc,p->doc);
            strcat(newdoc," (optional)");
            break;
        case '!':
            strcpy(newdoc,p->doc);
            strcat(newdoc," (required)");
            break;
        default:
            strcpy(newdoc,p->doc);
            strcat(newdoc," (default: ");
            strcat(newdoc,p->def);
            strcat(newdoc,")");
            break;
    }
    
    p->doc = newdoc;
    
    return NULL;
}

void rjvparser_help(struct myop*head,char*doc)
{
    struct myop*p;
    printf("%s\n\n",doc);
    
    p = head;
    while(p)
    {
        printf("    --%s=%s %s\n",p->name,p->type,p->doc);
        p = p->next;
    }
    
    printf("\n");
}

void rjvparser2(int argc,char**argv,struct myop*head,char*doc)
{
    unsigned i,flag=0;
    int len,ret;
    struct myop*p=NULL;
    char*pch=NULL;
    char**ppvar=NULL;
    
    //check for --help
    for(i=0; (int)i<argc; i++)
    {
        if(strcmp(argv[i],"--help") == 0 || strcmp(argv[i],"-h") == 0  || strcmp(argv[i],"-?") == 0)
        {
            break;
        }
    }
    
    if((int)i < argc || argc == 1)
    {
        rjvparser_help(head,doc);
        exit(0);
    }
    
    //parse all args
    for(i=1; (int)i<argc; i++)
    {
        p = head;
        flag = 0;
        while(p)
        {
            //find the =
            pch = strchr(argv[i],'=');

            //arg lacks an =
            if(pch == NULL)
            {
                rjvparser_help(head,doc);
                printf("malformed option: %s\n",argv[i]);
                exit(1);
            }
            
            len = pch - argv[i] - 2;
            
            if(strncmp(argv[i]+2,p->name,len) == 0)
            {
                flag = 1; //found the option
                break;
            }
            
            p = p->next;
        }
        
        //unknown option
        if(flag == 0)
        {
            rjvparser_help(head,doc);
            printf("unknown option: %s\n",argv[i]);
            exit(1);
        }
        
        pch += 1; //skip past the = to the option's value
        
        //printf("DEBUG:|%s|\n",pch);
        
        //parse the option's value
        switch(p->type[0])
        {
            case 'S':
                ppvar = (char**)p->pvar;
                if(*ppvar != NULL) free(*ppvar); //free any previous value
                assert(*ppvar = calloc(strlen(pch)+1,sizeof(char)));
                //ret = sscanf(pch,"%s",*ppvar); //only gets the first token
                strcpy(*ppvar,pch); //allows strings containing spaces, eg --inp="A B C"
                ret = 1;
                break;
            case 'I':
                ret = sscanf(pch,"%d",(int*)p->pvar);
                break;
            case 'U':
                ret = sscanf(pch,"%u",(unsigned*)p->pvar);
                break;
            case 'F':
                ret = sscanf(pch,"%lf",(double*)p->pvar);
                break;
            default:
                assert(0);
        }
        
        if(ret == 1)
        {
            p->assigned = 1;
            continue;
        }
        
        //failed to parse value
        rjvparser_help(head,doc);
        printf("failed to parse option: %s\n",argv[i]);
        exit(1);
    }
    
    //check for unassigned options
    p = head;
    flag = 0;

    while(p)
    {
        if(p->assigned == 0 && p->def[0] == '!')
        {
            flag = 1;
            printf("%s option is required\n",p->name);
        }
        
        p = p->next;
    }
    
    if(flag)
    {
        printf("\n");
        rjvparser_help(head,doc);
        exit(1);
    }
}
