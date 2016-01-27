#include "gg_utils.h"

#include <math.h>
#include <termios.h>
#include <unistd.h>

struct marker* new_marker(struct conf*c,char*buff)
{
    char name[BUFFER];
    char type[BUFFER];
    char phase[BUFFER];
    struct marker*m=NULL;
    size_t namelen;
    
    assert(m = calloc(1,sizeof(struct marker)));
    
    //set all 3 map positions to missing
    m->pos[0] = NO_POSN;
    m->pos[1] = NO_POSN;
    m->pos[2] = NO_POSN;
    
    //separate marker name, type and phase
    assert(sscanf(buff,"%s %s %s",name,type,phase) == 3);
    
    //copy marker name
    namelen = strlen(name);
    assert(m->name = calloc(namelen+1,sizeof(char)));
    strcpy(m->name,name);
    
    //check length of line is correct for the given marker name length and nind eg:
    //'NAME <hkxhk> {01} hk hk... hk hk\n'
    assert(strlen(buff) == namelen + 14 + 3*c->nind);
    
    /*
    parse marker type and phase
    expecting phase to be {xy}   x=>mat phase   y=>pat phase
    allocate memory for maternal and/or paternal genotype data
    
    phase information is ignored during grouping
    and can be set to arbitrary values if phase is not already known
    but phase is loaded because for test data it will already be known
    */
    switch(type[1])
    {
        case 'l':
            m->type = LMTYPE;
            
            if(phase[1] == '1') m->phase[0] = m->oldphase[0] = 1;
            
            assert(m->bits[0] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->mask[0] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->data[0] = calloc(c->nind,sizeof(VARTYPE)));
            assert(m->orig[0] = calloc(c->nind,sizeof(VARTYPE)));
            break;
            
        case 'n':
            m->type = NPTYPE;
            
            if(phase[2] == '1') m->phase[1] = m->oldphase[1] = 1;
            
            assert(m->bits[1] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->mask[1] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->data[1] = calloc(c->nind,sizeof(VARTYPE)));
            assert(m->orig[1] = calloc(c->nind,sizeof(VARTYPE)));
            break;
            
        case 'h':
            m->type = HKTYPE;
            
            if(phase[1] == '1') m->phase[0] = m->oldphase[0] = 1;
            if(phase[2] == '1') m->phase[1] = m->oldphase[1] = 1;
            
            assert(m->bits[0] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->bits[1] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->mask[0] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->mask[1] = calloc(c->nvar,sizeof(BITTYPE)));
            assert(m->data[0] = calloc(c->nind,sizeof(VARTYPE)));
            assert(m->data[1] = calloc(c->nind,sizeof(VARTYPE)));
            assert(m->orig[0] = calloc(c->nind,sizeof(VARTYPE)));
            assert(m->orig[1] = calloc(c->nind,sizeof(VARTYPE)));
            
            assert(m->code = calloc(c->nind,sizeof(VARTYPE)));
            break;
            
        default:
            assert(0);
    }
    
    return m;
}

//create marker from the data in the string
//treat as unphased
struct marker* create_marker_raw(struct conf*c,char*buff)
{
    struct marker*m=NULL;
    unsigned i;
    
    //alloc memory, load common data
    m = new_marker(c,buff);
    
    //read in individual genotype calls
    //data must be two characters per individual separated by one space
    buff += 14 + strlen(m->name);
    
    //marker segtype
    switch(m->type)
    {
        //<lmxll> ll lm --
        case LMTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    //missing
                    m->orig[0][i] = m->data[0][i] = MISSING;
                }
                else if(buff[3*i] != buff[3*i+1])
                {
                    //lm
                    m->orig[0][i] = m->data[0][i] = 1;
                }
            }
            break;
            
        //<nnxnp> nn np --
        case NPTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    //missing
                    m->orig[1][i] = m->data[1][i] = MISSING;
                }
                else if(buff[3*i] != buff[3*i+1])
                {
                    //np
                    m->orig[1][i] = m->data[1][i] = 1;
                }
            }
            break;
            
        //<hkxhk> hh hk kh kk --
        case HKTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    //missing
                    m->orig[0][i] = m->data[0][i] = MISSING;
                    m->orig[1][i] = m->data[1][i] = MISSING;
                    m->code[i] = MISSING;
                }
                else if(buff[3*i] != buff[3*i+1])
                {
                    //hk / kh must be treated as missing for Maliepaard 2pt rf
                    if(buff[3*i]   == 'k')             m->orig[0][i] = 1;
                    else                               m->orig[1][i] = 1;
                    m->data[0][i] = MISSING;
                    m->data[1][i] = MISSING;
                    m->code[i] = HK_CALL;
                }
                else if(buff[3*i] == 'k')
                {
                    //kk
                    m->orig[0][i] = m->data[0][i] = 1;
                    m->orig[1][i] = m->data[1][i] = 1;
                    m->code[i] = KK_CALL;
                }
                else
                {
                    //hh
                    m->orig[0][i] = m->data[0][i] = 0;
                    m->orig[1][i] = m->data[1][i] = 0;
                    m->code[i] = HH_CALL;
                }
            }
            break;
            
        default:
            assert(0);
    }
    
    return m;
}

//create marker from the data in the string
//treat as already phased
struct marker* create_marker_phased(struct conf*c,char*buff)
{
    struct marker*m=NULL;
    unsigned i;
    
    //alloc memory, load common data
    m = new_marker(c,buff);
    
    //read in individual genotype calls
    //data must be two characters per individual separated by one space
    buff += 14 + strlen(m->name);
    
    //marker segtype
    switch(m->type)
    {
        //<lmxll> valid allele codes: ll lm --
        case LMTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    m->orig[0][i] = m->data[0][i] = MISSING;          //missing
                    continue;
                }
                
                if(buff[3*i] != buff[3*i+1])       m->orig[0][i] = 1; //lm
                if(XOR(m->orig[0][i],m->phase[0])) m->data[0][i] = 1; //phased representation
            }
            break;
            
        //<nnxnp> valid allele codes: nn np --
        case NPTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    m->orig[1][i] = m->data[1][i] = MISSING;          //missing
                    continue;
                }
                
                if(buff[3*i] != buff[3*i+1])       m->orig[1][i] = 1; //np
                if(XOR(m->orig[1][i],m->phase[1])) m->data[1][i] = 1; //phased representation
            }
            break;
            
        //<hkxhk> valid allele codes: hh hk kh kk --
        // hk and kh are treated as fully imputed calls to allow hk-known test data to be loaded
        // but gibbs will always reimpute them and use the original hk/kh data for comparison only
        // if show_hkcheck is enabled
        case HKTYPE:
            for(i=0; i<c->nind; i++)
            {
                if(buff[3*i] == '-' || buff[3*i+1] == '-')
                {
                    m->orig[0][i] = m->data[0][i] = MISSING;   //missing
                    m->orig[1][i] = m->data[1][i] = MISSING;
                    m->code[i] = MISSING;
                    continue;
                }
        
                if(buff[3*i] != buff[3*i+1])
                {
                    if(buff[3*i] == 'k') m->orig[0][i] = 1;     //kh
                    else                 m->orig[1][i] = 1;     //hk
                    m->data[0][i] = MISSING;                    //hk/kh - treated as missing for initial 2pt rf
                    m->data[1][i] = MISSING;
                    m->code[i] = HK_CALL;
                    continue;
                }
                
                if(buff[3*i] == 'k')
                {
                    m->orig[0][i] = 1;                         //kk
                    m->orig[1][i] = 1;
                    m->code[i] = KK_CALL;
                }
                else
                {
                    m->code[i] = HH_CALL;                      //hh
                }
                
                if(XOR(m->orig[0][i],m->phase[0])) m->data[0][i] = 1; //phased representation
                if(XOR(m->orig[1][i],m->phase[1])) m->data[1][i] = 1;
            }
            break;
            
        default:
            assert(0);
    }
    
    return m;
}


//load marker data into marker array
//loads unphased, ungrouped data
void load_raw(struct conf*c,const char*fname)
{
    FILE*f=NULL;
    char buff[BUFFER];
    unsigned i;

    //open input file
    assert(f = fopen(fname,"rb"));

    //skip name, pop type
    assert(fgets(buff,BUFFER,f));
    assert(fgets(buff,BUFFER,f));
    
    //read nloc (number of markers)
    assert(fgets(buff,BUFFER,f));
    assert(sscanf(buff,"%*s %*s %u",&c->nmarkers) == 1);
    
    //read nind (number of individuals)
    assert(fgets(buff,BUFFER,f));
    assert(sscanf(buff,"%*s %*s %u",&c->nind) == 1);
    
    //calculate how many BTYPE variables needed to contain this number of bits
    c->nvar = (c->nind + BITSIZE - 1) / BITSIZE;

    //edge list will be expanded as required
    c->nedgemax = 10000;
    assert(c->elist = calloc(c->nedgemax,sizeof(struct edge*)));
    
    assert(c->array = calloc(c->nmarkers,sizeof(struct marker*)));
    
    //load each marker
    for(i=0; i<c->nmarkers; i++)
    {
        while(1)
        {
            //skip comments
            assert(fgets(buff,BUFFER,f));
            assert(strlen(buff) < BUFFER-1);
            if(buff[0] != ';') break;
        }

        //create unphased marker
        c->array[i] = create_marker_raw(c,buff);
    }
    
    fclose(f);
}

/*
load marker data into marker array
loads only one lg at a time
*/
void load_phased_lg(struct conf*c,const char*fname,const char*lg)
{
    FILE*f=NULL;
    char buff[BUFFER];
    char buff2[BUFFER];
    unsigned i,nmarkers;

    //edge list will be expanded as required
    c->nedgemax = 10000;
    assert(c->elist = calloc(c->nedgemax,sizeof(struct edge*)));

    /*open input file*/
    assert(f = fopen(fname,"rb"));

    /*skip name, pop type and nloc*/
    assert(fgets(buff,BUFFER,f));
    assert(fgets(buff,BUFFER,f));
    assert(fgets(buff,BUFFER,f));
    
    /*read nind (number of individuals)*/
    assert(fgets(buff,BUFFER,f));
    assert(sscanf(buff,"%*s %*s %u",&c->nind) == 1);
    
    /*calculate how many BITTYPE variables needed to contain this number of bits*/
    c->nvar = (c->nind + BITSIZE - 1) / BITSIZE;

    /*skip to the appropriate linkage group*/
    while(1)
    {
        assert(fgets(buff,BUFFER,f));
        
        /*ignore if not a comment line*/
        if(buff[0] != ';') continue;
        
        /*each linkage group must have a header line like:   ; group GROUPNAME markers NMARKERS*/
        assert(sscanf(buff,"%*s %*s %s %*s %u",buff2,&nmarkers) == 2);
        
        if(strcmp(buff2,lg) == 0) break;
    }

    /*allocate the marker arrays*/
    c->nmarkers = nmarkers;
    
    assert(c->array = calloc(c->nmarkers,sizeof(struct marker*)));
    assert(c->mutant = calloc(c->nmarkers,sizeof(struct marker*)));
    
    /*load each marker*/
    for(i=0; i<c->nmarkers; i++)
    {
        assert(fgets(buff,BUFFER,f));
        
        assert(strlen(buff) < BUFFER-1);

        //create marker
        c->array[i] = create_marker_phased(c,buff);
    }
    
    fclose(f);
    
}

/*
load all linkage groups
treat as phased and fully imputed
*/
void load_phased_all(struct conf*c,const char*fname)
{
    FILE*f=NULL;
    char buff[BUFFER];
    unsigned i;
    int lg;

    /*open input file*/
    assert(f = fopen(fname,"rb"));

    /*skip name, pop type and nloc*/
    assert(fgets(buff,BUFFER,f));
    assert(fgets(buff,BUFFER,f));

    /*read nloc (total number of markers)*/
    assert(fgets(buff,BUFFER,f));
    assert(sscanf(buff,"%*s %*s %u",&c->nmarkers) == 1);
    
    /*read nind (number of individuals)*/
    assert(fgets(buff,BUFFER,f));
    assert(sscanf(buff,"%*s %*s %u",&c->nind) == 1);
    
    /*calculate how many BITTYPE variables needed to contain this number of bits*/
    c->nvar = (c->nind + BITSIZE - 1) / BITSIZE;
    
    assert(c->array = calloc(c->nmarkers,sizeof(struct marker*)));
    
    lg=-1;
    
    /*read all markers*/
    for(i=0; i<c->nmarkers; i++)
    {
        while(1)
        {
            /*read next line*/
            assert(fgets(buff,BUFFER,f));
            
            if(buff[0] == ';')
            {
                /*treat as start of next lg*/
                lg+=1;
                continue;
            }
            
            break;
        }
        
        assert(strlen(buff) < BUFFER-1);

        /*create marker*/
        c->array[i] = create_marker_phased(c,buff);
        c->array[i]->lg = lg;
    }
    
    compress_to_bitstrings(c,c->nmarkers,c->array);
    
    fclose(f);
}

//count hk genotypes and allocate data structures for them
void alloc_hks(struct conf*c)
{
    struct marker*m=NULL;
    unsigned i,j;
    
    //count number of hk genotype calls
    c->nhk = 0;
    for(i=0; i<c->nmarkers; i++)
    {
        m = c->array[i];
        if(m->type != HKTYPE) continue;
        
        for(j=0; j<c->nind; j++)
        {
            //ignore if not an hk or kh
            if(m->orig[0][j] != m->orig[1][j]) c->nhk += 1;
        }
    }
    
    //allocate space for recording positions of hk alleles
    assert(c->hklist = calloc(c->nhk,sizeof(struct hk*)));
    for(i=0; i<c->nhk; i++) assert(c->hklist[i] = calloc(1,sizeof(struct hk)));
}

void alloc_distance_cache(struct conf*c)
{
    unsigned i,x;
    
    for(x=0; x<2; x++)
    {
        assert(c->cache[x] = calloc(c->nmarkers,sizeof(unsigned*)));
        
        for(i=0; i<c->nmarkers; i++)
        {
            //alloc only for cache[x][i][j] where j <= i
            assert(c->cache[x][i] = calloc(i+1,sizeof(unsigned)));
        }
    }
}

//find number of recombinants (R) and total comparable genotype calls (N)
//between two markers, treating the data in m1/m2->data as if it were in coupling phase
//or already phase adjusted
void calc_RN_simple(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,unsigned*R,unsigned*N)
{
    unsigned i;
    BITTYPE bits,mask;
    
    if(c->gg_bitstrings)
    {
        *R = 0;
        *N = 0;
        for(i=0; i<c->nvar; i++)
        {
            mask = m1->mask[x][i] & m2->mask[x][i];  //set bit if both values are non-missing
            bits = m1->bits[x][i] ^ m2->bits[x][i];  //set bit if values differ
            *N += POPCNT(mask);                      //count number of non-missing values
            *R += POPCNT(bits & mask);               //count bits which differ and are non-missing
        }
    }
    else
    {
        *R = 0;
        *N = c->nind;
        for(i=0; i<c->nind; i++)
        {
            //missing data never contribute any recomb events
            if(m1->data[x][i] == MISSING || m2->data[x][i] == MISSING)
            {
                *N -= 1;//reduce effective population size
                continue;
            }
            
            if(m1->data[x][i] != m2->data[x][i]) *R += 1;
        }
    }
}

/*
calculate magnitude of Pearson correlation coefficient
assuming correct marker order corresponds with original ordering in file
*/
void show_pearson_all(struct conf*c)
{
    unsigned i;
    double p;
    
    for(i=0; i<c->nlgs; i++)
    {
        //pearson correlation coefficient per LG
        p = calc_pearson(c->lg_nmarkers[i],c->lg_markers[i]);
        fprintf(c->flog,"#lg %u Pearson correlation coefficient %f\n",i,p);
    }
}

//calculate magnitude of Pearson correlation coefficient
//between current and true order
double calc_pearson(unsigned n,struct marker**marray)
{
    unsigned i;
    struct marker*m=NULL;
    double cov=0.0,xsd=0.0,ysd=0.0,mean;
    
    mean = ((double)n - 1.0)/2.0;
    
    for(i=0; i<n; i++)
    {
        m = marray[i];
        cov += ((double)i - mean) * ((double)m->true_posn - mean);
        xsd += ((double)i - mean) * ((double)i - mean);
        ysd += ((double)m->true_posn - mean) * ((double)m->true_posn - mean);
    }
    
    cov /= (double)n;               //covariance
    xsd = sqrt(xsd / (double)n);    //x std dev
    ysd = sqrt(ysd / (double)n);    //y std dev
    
    //pearson correllation coefficient
    return fabs(cov / (xsd * ysd));
}

//qsort markers alphabetically by marker name
int mpos_comp(const void*p1,const void*p2)
{
    struct marker*m1 = *((struct marker**)p1);
    struct marker*m2 = *((struct marker**)p2);

    return strcmp(m1->name,m2->name);
}

//extract presumed true map position from alphabetical ordering of marker names
//to enable calculation of the Pearson correlation coefficient during map ordering
void set_true_positions(unsigned n,struct marker**marray)
{
    unsigned i;
    struct marker**atmp=NULL;
    
    //make temporary array of marker pointers
    assert(atmp = calloc(n,sizeof(struct marker*)));
    memcpy((void*)atmp,(void*)marray, n*sizeof(struct marker*));
    
    //sort alphabetically by name
    qsort(atmp,n,sizeof(struct marker*),mpos_comp);
    
    /*printf("check alphabetic sort\n");
    for(i=0; i<n; i++) printf("%s\n",atmp[i]->name);*/

    //assign position
    for(i=0; i<n; i++) atmp[i]->true_posn = i;
    
    free(atmp);
}

//assign unique, random uids
//not related to true position or file position
void assign_uids(unsigned n,struct marker**marray)
{
    unsigned i,j;
    struct marker**atmp=NULL;
    struct marker*mtmp=NULL;
    
    //make temporary array of marker pointers
    assert(atmp = calloc(n,sizeof(struct marker*)));
    memcpy((void*)atmp,(void*)marray, n*sizeof(struct marker*));
    
    //shuffle into random order
    for(i=0; i<n; i++)
    {
        j = rand() % n;
        SWAP(atmp[i],atmp[j],mtmp);
    }
    
    //assign uid from position
    for(i=0; i<n; i++) atmp[i]->uid = i;
    
    free(atmp);
}

void random_bitstring(struct conf*c,BITTYPE*bits)
{
    unsigned i,y,z;
    
    for(i=0; i<c->nind; i++)
    {
        y = i / BITSIZE;
        z = i % BITSIZE;
        if(drand48() < 0.5) bits[y] = SET_BIT(bits[y],z);
        else                bits[y] = CLEAR_BIT(bits[y],z);
    }
}

/*
set nmarkers and nind, then call this
to create a random map in elite
with a copy of the order in mutant
*/
#if 0
void create_random_map(struct conf*c)
{
    unsigned i;
    struct marker*m=NULL;
    
    assert(c->array = calloc(c->nmarkers,sizeof(struct marker*)));
    assert(c->mutant = calloc(c->nmarkers,sizeof(struct marker*)));
    
    c->nvar = (c->nind + BITSIZE - 1)/BITSIZE;
    
    for(i=0; i<c->nmarkers; i++)
    {
        assert(m = calloc(1,sizeof(struct marker)));
        
        assert(m->name = calloc(10,sizeof(char)));
        
        c->array[i] = m;
        c->mutant[i] = m;
        
        sprintf(m->name,"m%03d",i);
        
        switch(rand()%3)
        {
            case 0:
                //alloc maternal info only
                m->type = LMTYPE;
                assert(m->bits[0] = calloc(c->nvar,sizeof(BITTYPE)));
                random_bitstring(c,m->bits[0]);
                break;
            case 1:
                //alloc paternal info only
                m->type = NPTYPE;
                assert(m->bits[1] = calloc(c->nvar,sizeof(BITTYPE)));
                random_bitstring(c,m->bits[1]);
                break;
            case 2:
                //alloc both
                m->type = HKTYPE;
                assert(m->bits[0] = calloc(c->nvar,sizeof(BITTYPE)));
                assert(m->bits[1] = calloc(c->nvar,sizeof(BITTYPE)));
                random_bitstring(c,m->bits[0]);
                random_bitstring(c,m->bits[1]);
                break;
        }
    }
}
#endif

/*
print the ordered linkage group to stdout
*/
void print_order(struct conf*c,struct marker**marray,FILE*f)
{
    struct marker*m=NULL;
    unsigned i,j;
    
    fprintf(f,"; group %s markers %u\n",c->lg,c->nmarkers);
    for(i=0; i<c->nmarkers; i++)
    {
        m = marray[i];
        fprintf(f,"%s ",m->name);
        switch(m->type)
        {
            case LMTYPE:
                fprintf(f,"<lmxll> ");
                if(m->phase[0]) fprintf(f,"{1-}");
                else            fprintf(f,"{0-}");
                for(j=0; j<c->nind; j++)
                {
                    /*XOR genotype bit and phase*/
                    if(XOR(m->data[0][j],m->phase[0])) fprintf(f," lm");
                    else                               fprintf(f," ll");
                }
                break;
            case NPTYPE:
                fprintf(f,"<nnxnp> ");
                if(m->phase[1]) fprintf(f,"{-1}");
                else            fprintf(f,"{-0}");
                for(j=0; j<c->nind; j++)
                {
                    /*XOR genotype bit and phase*/
                    if(XOR(m->data[1][j],m->phase[1])) fprintf(f," np");
                    else                               fprintf(f," nn");
                }
                break;
            case HKTYPE:
                fprintf(f,"<hkxhk> ");
                if(m->phase[0]) fprintf(f,"{1");
                else            fprintf(f,"{0");
                if(m->phase[1]) fprintf(f,"1}");
                else            fprintf(f,"0}");
                for(j=0; j<c->nind; j++)
                {
                    /*XOR genotype bit and phase*/
                    if(XOR(m->data[0][j],m->phase[0])) fprintf(f," k");
                    else                               fprintf(f," h");
                    if(XOR(m->data[1][j],m->phase[1])) fprintf(f,"k");
                    else                               fprintf(f,"h");
                }
                break;
            default:
                assert(0);
        }
        fprintf(f,"\n");
    }
}

/*
count recombination events and non-missing values between two genotype arrays
*/
void utils_count_events(struct conf*c,VARTYPE*d1,VARTYPE*d2,unsigned*R,unsigned*N)
{
    unsigned i;
    
    *N = c->nind;
    *R = 0;
    
    for(i=0; i<c->nind; i++)
    {
        if(d1[i] == MISSING || d2[i] == MISSING)
        {
            *N -= 1;
        }
        else if(d1[i] != d2[i])
        {
            *R += 1;
        }
    }
}

//produce maternal / paternal map positions from the current marker order
void indiv_map_positions(struct conf*c,struct marker**marray,unsigned x)
{
    struct marker*m=NULL;
    unsigned i,R,N;
    double rf,dist;
    int prev;
    
    dist = 0.0;
    prev = -1;
    for(i=0; i<c->nmarkers; i++)
    {
        m = marray[i];
        if(m->data[x] == NULL)
        {
            m->pos[x] = NO_POSN;
            continue;
        }
        
        if(prev != -1)
        {
            //find distance to previous marker
            calc_RN_simple(c,marray[prev],marray[i],x,&R,&N);
            assert(N != 0);
            rf = (double)R / N;
            if(rf > MAX_RF) rf = MAX_RF;
            dist += c->map_func(rf);
        }
        
        m->pos[x] = dist;
        prev = i;
    }
}

//if covariance between maternal and paternal positions is negative
//invert order of paternal positions
void check_invert_paternal(unsigned n,struct marker**marray)
{
    struct marker*m=NULL;
    unsigned count[2] = {0,0};
    double mean[2] = {0.0,0.0};
    double cov_sign=0.0,maxpat=-1.0;
    unsigned i,x;
    
    //find sign of covariance between mat and pat position for hks
    for(x=0; x<2; x++)
    {
        for(i=0; i<n; i++)
        {
            m = marray[i];
            if(m->type != HKTYPE) continue;
            mean[x] += m->pos[x];
            count[x] += 1;
        }
        
        //cannot work out relative orientation with less than 2 hk markers
        assert(count[x] > 1);
        
        mean[x] /= (double)count[x];
    }
    
    for(i=0; i<n; i++)
    {
        m = marray[i];
        
        //find max pat map positions
        if(m->data[1]) if(m->pos[1] > maxpat) maxpat = m->pos[1];
        if(m->type != HKTYPE) continue;
        cov_sign += (m->pos[0]-mean[0]) * (m->pos[1]-mean[1]);
    }
    
    //if covariance is negative, invert paternal positions
    if(cov_sign < 0.0)
    {
        for(i=0; i<n; i++)
        {
            m = marray[i];
            if(m->data[1]) m->pos[1] = maxpat - m->pos[1];
        }
    }
}

//combine maternal and paternal map positions to give final estimated order
void comb_map_positions(struct conf*c,unsigned n,struct marker**marray,unsigned lg,unsigned flip_check)
{
    struct marker*m=NULL;
    unsigned i,nhk;
    
    //ensure there are at least two hk markers in this lg
    nhk = 0;
    for(i=0; i<n; i++)
    {
        m = marray[i];
        m->pos[2] = NO_POSN;
        if(m->type == HKTYPE) nhk += 1;
    }
    
    if(nhk < 2)
    {
        if(c->flog) fprintf(c->flog,"#lg %u has less than 2 hk markers, cannot produce combined map\n",lg);
        return;
    }
    
    //flip paternal map positions if reversed wrt maternal
    //does nothing if less than two hk markers in this lg
    if(flip_check) check_invert_paternal(n,marray);
    
    //interpolate / extrapolate lm/np positions from averaged hk positions
    combine_maps(n,marray);
}

//sort markers by maternal map position
int mcomp_matpos(const void*_m1, const void*_m2)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    
    m1 = *((struct marker**)_m1);
    m2 = *((struct marker**)_m2);
    
    if(m1->pos[0] < m2->pos[0]) return -1;
    if(m1->pos[0] > m2->pos[0]) return 1;
    return 0;
}

//sort markers by combined map position
int mcomp_combpos(const void*_m1, const void*_m2)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    
    m1 = *((struct marker**)_m1);
    m2 = *((struct marker**)_m2);
    
    if(m1->pos[2] < m2->pos[2]) return -1;
    if(m1->pos[2] > m2->pos[2]) return 1;
    return 0;
}

//sort markers by paternal map position
int mcomp_patpos(const void*_m1, const void*_m2)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    
    m1 = *((struct marker**)_m1);
    m2 = *((struct marker**)_m2);
    
    if(m1->pos[1] < m2->pos[1]) return -1;
    if(m1->pos[1] > m2->pos[1]) return 1;
    return 0;
}

//combine maternal and paternal map positions to give final estimated order
void combine_maps(unsigned n,struct marker**marray)
{
    struct marker*m=NULL;
    struct marker*m2=NULL;
    struct marker*prevhk=NULL;
    struct marker*nexthk=NULL;
    struct marker*lasthk=NULL;
    double offset;
    unsigned i,j,x,nhk;   
    
    //average hk positions
    nhk = 0;
    for(i=0; i<n; i++)
    {
        m = marray[i];
        if(m->type != HKTYPE) continue;
        m->pos[2] = (m->pos[0] + m->pos[1]) / 2.0;
        nhk += 1;
    }
    
    //combined map needs at least 2 hks per lg
    assert(nhk > 1);

    //interpolate / extrapolate positions of lm/np markers
    //based on flanking hk markers
    for(x=0; x<2; x++)
    {
        if(x == 0)
        {
            //sort by maternal order
            qsort(marray,n,sizeof(struct marker*),mcomp_matpos);
        }
        else
        {
            //sort by paternal order
            qsort(marray,n,sizeof(struct marker*),mcomp_patpos);
        }
        
        prevhk = NULL;
        nexthk = NULL;
        
        //find last hk in the lg
        for(i=n-1; i<n; i--) //relying on underflow of an unsigned should be portable
        {
            m = marray[i];
            if(m->type == HKTYPE)
            {
                lasthk = m;
                break;
            }
        }
        
        assert(lasthk);
        
        for(i=0; i<n; i++)
        {
            m = marray[i];
            if(!m->data[x]) continue;//ignore markers of wrong type
            
            if(m->type == HKTYPE)
            {
                prevhk = m;
                nexthk = NULL;
                continue;
            }
            
            //printf("right type\n");
            
            //find next hk(if any)
            if(nexthk == NULL && prevhk != lasthk)
            {
                for(j=i+1; j<n; j++)
                {
                    m2 = marray[j];
                    if(m2->type == HKTYPE)
                    {
                        nexthk = m2;
                        break;
                    }
                }
            }
            
            if(prevhk == NULL)
            {
                //before first hk
                m->pos[2] = m->pos[x] - nexthk->pos[x] + nexthk->pos[2];
                //printf("prev => %f\n",m->pos[2]);
            }
            else if(nexthk == NULL)
            {
                //after last hk
                m->pos[2] = m->pos[x] - prevhk->pos[x] + prevhk->pos[2];
                //printf("next => %f\n",m->pos[2]);
            }
            else
            {
                //inbetween two hks
                m->pos[2] = m->pos[x] - prevhk->pos[x];
                
                if(nexthk->pos[x] - prevhk->pos[x] > 0.0) //avoid div by zero of pos prev == next
                {
                    m->pos[2] /= nexthk->pos[x] - prevhk->pos[x];
                }
                
                m->pos[2] *= nexthk->pos[2] - prevhk->pos[2];
                m->pos[2] += prevhk->pos[2];
                //printf("between => %f\n",m->pos[2]);
            }
        }
    }
    
    //sort by combined map position
    qsort(marray,n,sizeof(struct marker*),mcomp_combpos);
    offset = marray[0]->pos[2];
    
    //ensure first position is zero
    for(i=0; i<n; i++)
    {
        m = marray[i];
        m->pos[2] -= offset;
    }

    /*char *labels[] = {"","<lmxll>","<nnxnp>","<hkxhk>"};
    for(i=0; i<n; i++)
    {
        m = marray[i];
        printf("%s %s %f\n",m->name,labels[m->type],m->pos[2]);
    }*/
}

//calculate and print the final map positions
void print_map(unsigned n,struct marker**marray,FILE*f,unsigned lg_numb,const char*lg_name)
{
    struct marker*m=NULL;
    unsigned i,x;
    
    if(lg_name) fprintf(f,"group %s ; markers %u\n",lg_name,n);
    else        fprintf(f,"group %03u ; markers %u\n",lg_numb,n);
    
    for(i=0; i<n; i++)
    {
        m = marray[i];
        fprintf(f,"%s",m->name);
        for(x=0; x<3; x++)
        {
            if(m->pos[x] == NO_POSN) fprintf(f,"\t%8s","NA");
            else                     fprintf(f,"\t%8.4f",m->pos[x]);
        }
        fprintf(f,"\n");
    }
}


#if 0
//old version
void print_map(struct conf*c,struct marker**marray,FILE*f)
{
    struct marker*m=NULL;
    unsigned i,x,R,N,j,k;
    double (*mfunc)(double)=NULL;
    double rf,dist;
    int y,z,prev;
    
    /*calculate maternal/paternal map positions*/
    for(x=0; x<2; x++)
    {
        /*find first marker*/
        prev = -1;
        for(i=0; i<c->nmarkers && prev==-1; i++)
        {
            m = marray[i];
            if(m->data[x] == NULL)
            {
                m->pos[x] = NO_POSN;
                continue;
            }
            
            m->pos[x] = 0.0;
            prev = i;
        }
        
        /*deal with subsequent markers*/
        for( ; i<c->nmarkers; i++)
        {
            m = marray[i];
            if(m->data[x] == NULL)
            {
                m->pos[x] = NO_POSN;
                continue;
            }
            
            //R = utils_count_events(c,marray[prev]->data[x],marray[i]->data[x]);
            utils_count_events(c,marray[prev]->data[x],marray[i]->data[x],&R,&N);
            assert(N != 0);
            rf = (double)R / (double)N;
            
            if(rf > MAX_RF) rf = MAX_RF;
            
            dist = c->map_func(rf);

            m->pos[x] = marray[prev]->pos[x] + dist;
            prev = i;
        }
    }

    /*
    combined map
    deal with hk markers
    */
    for(i=0; i<c->nmarkers; i++)
    {
        m = marray[i];
        if(m->type != HKTYPE)
        {
            m->pos[2] = NO_POSN;
            continue;
        }
        
        /*average of position in mat and pat maps*/
        m->pos[2] = 0.5 * (m->pos[0] + m->pos[1]);
    }
    
    /*
    find first hk marker
    */
    for(i=0; i<c->nmarkers; i++)
    {
        if(marray[i]->type == HKTYPE) break;
    }
    
    j = i;
    
    /*
    extrapolate lm and np position for initial markers
    */
    for(i=0; i<j && j<c->nmarkers; i++)
    {
        m = marray[i];
        for(x=0; x<2; x++)
        {
            if(!m->data[x]) continue;
            m->pos[2] = marray[j]->pos[2] - (marray[j]->pos[x] - m->pos[x]);
        }
    }
    
    /*
    find last hk marker
    */
    for(y=c->nmarkers-1; y>0; y--)
    {
        if(marray[y]->type == HKTYPE) break;
    }
    
    z = y;
    
    /*
    extrapolate lm and np position for initial markers
    */
    for(y=c->nmarkers-1; y>z && z>0; y--)
    {
        m = marray[y];
        for(x=0; x<2; x++)
        {
            if(!m->data[x]) continue;
            m->pos[2] = marray[z]->pos[2] + m->pos[x] - marray[z]->pos[x];
        }
    }
    
    /*
    interpolate lm and np positions for internal markers
    */
    i = 0;
    while(1)
    {
        /*find first hk*/
        for(; i<c->nmarkers; i++)
        {
            if(marray[i]->type == HKTYPE) break;
        }
        if(i >= c->nmarkers) break;//end of map

        /*find next hk*/
        for(j=i+1; j<c->nmarkers; j++)
        {
            if(marray[j]->type == HKTYPE) break;
        }
        if(j >= c->nmarkers) break;//end of map
        
        /*interpolate intervening markers*/
        for(k=i+1; k<j; k++)
        {
            m = marray[k];
            for(x=0; x<2; x++)
            {
                if(!m->data[x]) continue;
                if(m->pos[x] - marray[i]->pos[x] <= 0.0)
                {
                    m->pos[2] = 0.0;
                }
                else
                {
                    m->pos[2] = (m->pos[x] - marray[i]->pos[x])
                              / (marray[j]->pos[x] - marray[i]->pos[x]);
                }
                
                m->pos[2] *= marray[j]->pos[2] - marray[i]->pos[2];
                m->pos[2] += marray[i]->pos[2];
            }
        }
        
        /*second hk becomes first*/
        i=j;
    }
    
    //sort markers by position in combined map
    qsort(marray,c->nmarkers,sizeof(struct marker*),mpos_printorder);
    
    for(i=1; i<c->nmarkers-1; i++)
    {
        marray[i]->pos[2] -= marray[0]->pos[2];
    }
    marray[0]->pos[2] = 0.0;
    
    fprintf(f,"group %s ; markers %u\n",c->lg,c->nmarkers);
    for(i=0; i<c->nmarkers; i++)
    {
        m = marray[i];
        fprintf(f,"%s",m->name);
        for(x=0; x<3; x++)
        {
            if(m->pos[x] == NO_POSN) fprintf(f,"\t%8s","NA");
            else                     fprintf(f,"\t%8.4f",m->pos[x]);
        }
        fprintf(f,"\n");
    }
}
#endif

//qsort markers  by pos[2]
int mpos_printorder(const void*p1,const void*p2)
{
    struct marker*m1 = *((struct marker**)p1);
    struct marker*m2 = *((struct marker**)p2);

    if(m1->pos[2] < m2->pos[2]) return -1;
    if(m1->pos[2] > m2->pos[2]) return 1;
    return 0;
}

//calculate genetic distance (in centimorgans)
//from the recombination fraction
double kosambi(double r)
{
    return 50.0 * atanh(2.0*r);
}

//calculate genetic distance (in centimorgans)
//from the recombination fraction
double haldane(double r)
{
    return -50.0 * log(1.0 - 2.0*r);
}

//shuffle markers into random order
void randomise_order(unsigned n,struct marker**marray)
{
    unsigned i,j;
    struct marker*mtmp=NULL;
    
    for(i=0; i<n; i++)
    {
        j = rand() % n;
        SWAP(marray[i],marray[j],mtmp);
    }
}

void print_bits_inner(struct conf*c,struct marker**marray)
{
    unsigned i,j,x,flag;
    struct marker*m=NULL;
    
    for(i=0; i<c->nmarkers && i<c->gg_show_height; i++)
    {
        m = marray[i];
        
        for(j=0; j<c->nind && j<c->gg_show_width; j++)
        {
            flag = 0;
            if(m->type == HKTYPE) if(m->orig[0][j] != m->orig[1][j]) flag = 1; //gibbs imputed
            
            if(flag) printf("[");
            else     printf(" ");
            
            for(x=0; x<2; x++)
            {
                if(m->data[x])
                {
                    if(m->data[x][j] == 1)
                    {
                        if(m->data[x][j] != (unsigned)XOR(m->orig[x][j],m->phase[x]) && c->gg_show_hkcheck) printf("i");
                        else                                                                               printf("1");
                    }
                    if(m->data[x][j] == 0)
                    {
                        if(m->data[x][j] != (unsigned)XOR(m->orig[x][j],m->phase[x]) && c->gg_show_hkcheck) printf("o");
                        else                                                                                printf("0");
                    }
                    if(m->data[x][j] == MISSING) printf("-");
                }
                else
                {
                    printf("|");
                }
            }
            
            if(flag) printf("] ");
            else     printf("  ");
        }

        printf("\n");
    }
}

/*
show the raw bit states as a block
*/
void print_bits(struct conf*c,struct marker**marray,unsigned pause)
{
    char buff[100];
    struct termios t1, t2;
    
    //show bits
    print_bits_inner(c,marray);
    
    if(pause)
    {
        /*wait for ENTER to be pressed without echoing it*/
        assert(tcgetattr(STDIN_FILENO, &t1) == 0);
        t2 = t1;
        t1.c_lflag &= ~ECHO;
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &t1);
        if(fgets(buff,98,stdin)){};
        tcsetattr(STDIN_FILENO, TCSANOW, &t2);
    }
}

/*
convert data into bitstring representation
*/
void compress_to_bitstrings(struct conf*c,unsigned n,struct marker**marray)
{
    struct marker*m=NULL;
    unsigned i,x;
    
    for(i=0; i<n; i++)
    {
        m = marray[i];
        
        for(x=0; x<2; x++)
        {
            if(m->data[x]) to_bitstring(c,m->data[x],m->bits[x],m->mask[x]);
        }
    }
}

/*
pack data into bitstrings representing state (bits) and missing data (mask)
*/
void to_bitstring(struct conf*c,VARTYPE*data,BITTYPE*bits,BITTYPE*mask)
{
    unsigned i,y,z;
    
    for(i=0; i<c->nvar; i++) bits[i] = mask[i] = 0;

    for(i=0; i<c->nind; i++)
    {
        y = i / BITSIZE;
        z = i % BITSIZE;
        
        if(data[i] == 0)
        {
            //bits[y] = CLEAR_BIT(bits[y],z);
            mask[y] = SET_BIT(mask[y],z);
        }
        else if(data[i] == 1)
        {
            bits[y] = SET_BIT(bits[y],z);
            mask[y] = SET_BIT(mask[y],z);
        }
        else //data[i] == MISSING
        {
            //bits[y] = CLEAR_BIT(bits[y],z);
            //mask[y] = CLEAR_BIT(mask[y],z);
        }
    }
}

/*
unpack the bit string into the uchar arrays
*/
/*void from_bitstring(struct conf*c,BITTYPE*bits,unsigned char*data)
{
    BITTYPE i;
    BITTYPE mask;
    
    for(i=0; i<c->nind; i++)
    {
        mask = 1 << (i%BITSIZE);
        if(bits[i/BITSIZE] & mask) data[i] = (unsigned char)1;
        else                       data[i] = (unsigned char)0;
    }
}*/

/*
zero the R matrices
zero is used to indicate that the value has not yet been calculated
R values are always stored with +1 added to them which is removed before being returned
*/
void reset_r_matrix(struct conf*c)
{
    unsigned x,i;
    
    for(x=0; x<2; x++)
    {
        for(i=0; i<c->nmarkers; i++)
        {
            memset(c->cache[x][i], 0, (i+1)*sizeof(unsigned));
        }
    }
}

/*allocate and precalc the bitshift masks*/
void init_masks(struct conf*c)
{
    BITTYPE i;
    
    assert(c->precalc_mask = calloc(BITSIZE,sizeof(BITTYPE)));
    
    for(i=0; i<BITSIZE; i++)
    {
        c->precalc_mask[i] = (BITTYPE)1 << i;
    }
}
