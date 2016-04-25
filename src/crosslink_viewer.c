#include "crosslink_viewer.h"
#include "crosslink_utils.h"

//white,red,yellow,green,cyan,blue,black
unsigned palette[13][3] =
{
    {255,255,255},//white
    {255,128,128},
    {255,  0,  0},//red
    {255,128,  0},
    {255,255,  0},//yellow
    {128,255,  0},
    {  0,255,  0},//green
    {  0,255,128},
    {  0,255,255},//cyan
    {  0,128,255},      
    {  0,  0,255},//blue
    {  0,  0,128},
    { 32, 32, 32}//grey
};

//search for marker by name
unsigned find_marker(struct lg*p,char*name)
{
    unsigned i;
    
    for(i=0; i<p->nmarkers; i++) if(strcmp(p->array[i]->name,name) == 0) return i;//found it
    
    return p->nmarkers; //indicates not found
}

//print information about a single marker to the console
void show_info(struct lg*p,int offset)
{
    struct marker*m=NULL;
    m = p->array[offset];
    
    switch(m->type)
    {
        case LMTYPE:
            printf("(%d)%s LM {%d-} ",m->lg,m->name,m->phase[0]);
            break;
        case NPTYPE:
            printf("(%d)%s NP {-%d} ",m->lg,m->name,m->phase[1]);
            break;
        case HKTYPE:
            printf("(%d)%s HK {%d%d} ",m->lg,m->name,m->phase[0],m->phase[1]);
            break;
        default:
            assert(0);
    }
}

//calculate and print rf and lod information to console
void show_rf_lod(struct conf*c,struct lg*p,int xoff,int yoff)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    unsigned x,R,N,S;
    double rf,s,lod;
    
    m1 = p->array[xoff];
    m2 = p->array[yoff];

    //LM <=> NP
    if((m1->type == LMTYPE && m2->type == NPTYPE) || (m1->type == NPTYPE && m2->type == LMTYPE))
    {
        if(m1->type == LMTYPE) calc_RN_simple2(c,m1,m2,0,1,&R,&N);
        else                   calc_RN_simple2(c,m1,m2,1,0,&R,&N);

        if(N > 0)
        {
            rf = (double)R / N;
                    
            //calculate linkage LOD
            s = 1.0 - rf;
            S = N - R;
            
            lod = 0.0;
            if(s > 0.0) lod += S * log10(2.0*s);
            if(rf > 0.0) lod += R * log10(2.0*rf);
        }
        
        printf("N=%d rf=%.5lf lod=%.2lf ",N,rf,lod);
        return;
    }
    
    for(x=0; x<2; x++)
    {
        if(m1->data[x] && m2->data[x])
        {
            calc_RN_simple(c,m1,m2,x,&R,&N);
            if(N > 0)
            {
                rf = (double)R / N;
                
                //calculate linkage LOD
                s = 1.0 - rf;
                S = N - R;
                
                lod = 0.0;
                if(s > 0.0) lod += S * log10(2.0*s);
                if(rf > 0.0) lod += R * log10(2.0*rf);
            }
            
            if(x==0) printf("mat:");
            else     printf("pat:");
            printf("N=%d rf=%.5lf lod=%.2lf ",N,rf,lod);
        }
    }
}

//compare all against all markers calculate image pixel value based on rf and lod info
//lower triangle: colours: rf, brightness: lod, distinguish maternal/paternal
//upper triangle: colours: quantised map distance, brightness: remainder of map distance, merge maternal/paternal
uint32_t*generate_image(struct conf*c,struct lg*p,unsigned mode)
{
    uint32_t*buff=NULL;
    unsigned i,j,x,R,N,S,low[3],upp[3],tmpval;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    double rf,s,lod,dist,d[2];
    unsigned band;
    
    //pixel buffer
    assert(buff = calloc(p->nmarkers*p->nmarkers,sizeof(uint32_t)));
    
    //low[3] is RGB for lower triangle
    //upp[3] is RGB for upper triangle
    printf("generating...\n");
    for(i=0; i<p->nmarkers; i++)
    {
        m1 = p->array[i];
        for(j=i; j<p->nmarkers; j++)
        {
            m2 = p->array[j];
            
            if(i == j)
            {
                switch(m1->type)
                {
                    case LMTYPE:
                        setpixelrgb(buff,i,j,p->nmarkers,255,0,0);
                        break;
                    case NPTYPE:
                        setpixelrgb(buff,i,j,p->nmarkers,0,255,0);
                        break;
                    case HKTYPE:
                        setpixelrgb(buff,i,j,p->nmarkers,255,255,0);
                        break;
                }
                
                continue;
            }
            
            low[0] = low[1] = low[2] = 0;
            upp[0] = upp[1] = upp[2] = 0;
            
            dist = -1.0;
            d[0] = d[1] = -1.0;

            
            //for LM vs NP comparisions, compare the information anyway (otherwise it's just always black)
            //strong linkage will indicate we likely have an error in the marker typing
            //display as yellow
            if((m1->type == LMTYPE && m2->type == NPTYPE) || (m1->type == NPTYPE && m2->type == LMTYPE))
            {
                if(m1->type == LMTYPE) calc_RN_simple2(c,m1,m2,0,1,&R,&N);
                else                   calc_RN_simple2(c,m1,m2,1,0,&R,&N);

                if(N > 0)
                {
                    //calculate rf and linkage LOD
                    rf = (double)R / N;
                    s = 1.0 - rf;
                    S = N - R;
                    
                    lod = 0.0;
                    if(s > 0.0) lod += S * log10(2.0*s);
                    if(rf > 0.0) lod += R * log10(2.0*rf);
                    
                    //lower triangle: rf and lod info
                    if(rf <= 0.5)
                    {
                        //coupling linkage, yellow
                        //low[0] = low[1] = (0.5 - rf) * 2.0 * 255.999;
                        low[0] = low[1] = tanh(lod*LOD_BRIGHTNESS_SCALE) * (255.999 - LOD_BRIGHTNESS_MIN)
                                          + LOD_BRIGHTNESS_MIN;
                    }
                    else
                    {
                        //repulsion linkage, blue
                        low[2] = tanh(lod*LOD_BRIGHTNESS_SCALE) *  (255.999 - LOD_BRIGHTNESS_MIN)
                                          + LOD_BRIGHTNESS_MIN;
                    }
                }
            }
            else
            {
                for(x=0; x<2; x++)
                {
                    if(m1->data[x] && m2->data[x])
                    {
                        calc_RN_simple(c,m1,m2,x,&R,&N);
                        if(N > 0)
                        {
                            //calculate rf and linkage LOD
                            rf = (double)R / N;
                            s = 1.0 - rf;
                            S = N - R;
                            
                            lod = 0.0;
                            if(s > 0.0) lod += S * log10(2.0*s);
                            if(rf > 0.0) lod += R * log10(2.0*rf);
                            
                            //lower triangle: rf and lod info
                            if(rf <= 0.49999)
                            {
                                //coupling linkage, red or green
                                low[x] = tanh(lod*LOD_BRIGHTNESS_SCALE) * (255.999 - LOD_BRIGHTNESS_MIN)
                                                  + LOD_BRIGHTNESS_MIN;
                                d[x] = haldane(rf);
                            }
                            else
                            {
                                //repulsion linkage, blue
                                //indicate the strongest repulsion value of the two
                                tmpval = tanh(lod*LOD_BRIGHTNESS_SCALE) *  (255.999 - LOD_BRIGHTNESS_MIN)
                                                  + LOD_BRIGHTNESS_MIN;
                                if(low[2] < tmpval) low[2] = tmpval;
                                d[x] = haldane(0.49999);
                            }
                        }
                    }
                }
            }
            
            switch(mode)
            {
                case 0: //combined
                    if(d[0] >= 0.0 && d[1] >= 0.0) dist = (d[0] + d[1]) / 2.0;
                    else if(d[0] >= 0.0)           dist = d[0];
                    else if(d[1] >= 0.0)           dist = d[1];
                    break;
                case 1: //maternal only
                    if(d[0] >= 0.0) dist = d[0];
                    low[1] = 0;
                    break;
                case 2: //paternal only
                    if(d[1] >= 0.0) dist = d[1];
                    low[0] = 0;
                    break;
            }

            //upper triangle: map distance
            if(dist < 0.0)
            {
                upp[0] = upp[1] = upp[2] = 0;
            }
            else
            {
                band = round(dist / DIST_BAND);
                if(band > 12) band = 12;
                upp[0] = palette[band][0];
                upp[1] = palette[band][1];
                upp[2] = palette[band][2];
            }
            
            //generate checkerboard pattern denoting linkage group boundaries
            //in the blue channel of the "LOD" part of the graph
            if((m1->lg & 0x1) ^ (m2->lg & 0x1))
            {
                low[2] += 50;
                if(low[2] > 255) low[2] = 255;
                upp[2] += 50;
                if(upp[2] > 255) upp[2] = 255;
            }

            setpixelrgb(buff,i,j,p->nmarkers,low[0],low[1],low[2]);//rf-lod, lower
            setpixelrgb(buff,j,i,p->nmarkers,upp[0],upp[1],upp[2]);//distance, upper
        }
    }
    
    printf("done\n");
    
    return buff;
}

void which_markers(int mx,int my,SDL_Rect*img,SDL_Rect*win,int*imgx,int*imgy)
{
    double dx,dy;
    
    if(mx < win->x || mx >= win->x + win->w)
    {
        *imgx = -1;
    }
    else
    {
        dx = ((double)mx - win->x + 0.5) / win->w;
        *imgx = floor(dx * (double)img->w + img->x);
        if(*imgx > img->w + img->x - 1) *imgx = img->w + img->x - 1;
    }
    
    if(my < win->y || my >= win->y + win->h)
    {
        *imgy = -1;
    }
    else
    {
        dy = ((double)my - win->y + 0.5) / win->h;
        *imgy = floor(dy * (double)img->h + img->y);
        if(*imgy > img->h + img->y - 1) *imgy = img->h + img->y - 1;
    }
}

//calc which rectangle of image to blit to which rectangle in the window
void calc_view(unsigned img_size,unsigned win_size,double img_centrex,double img_centrey,double img_width,SDL_Rect*img,SDL_Rect*win)
{
    int winL,winR,imgL,imgR,imgW;
    
    imgL = floor((double)img_centrex - img_width / 2.0);
    imgR = floor((double)img_centrex + img_width / 2.0 - 0.00001);
    imgW = imgR - imgL + 1;
    
    //printf("imgL=%d, imgR=%d\n",imgL,imgR);
    
    winL = 0;
    winR = win_size - 1;
    
    if(imgL < 0)
    {
        //some portion of the left will be blank
        winL = floor(-(double)imgL / imgW * win_size);
        imgL = 0;
        //printf("winL=%d,imgL=%d\n",winL,imgL);
    }
    
    if(imgR >= (int)img_size)
    {
        //some portion of the right will be blank
        winR = win_size - 1 - floor(((double)imgR - img_size + 1.0) / imgW * win_size);
        imgR = img_size - 1;
        //printf("winR=%d,imgR=%d\n",winR,imgR);
    }
    
    img->x = imgL;
    img->w = imgR - imgL + 1;

    win->x = winL;
    win->w = winR - winL + 1;

    imgL = floor((double)img_centrey - img_width / 2.0);
    imgR = floor((double)img_centrey + img_width / 2.0 - 0.00001);
    imgW = imgR - imgL + 1;
    
    //printf("imgL=%d, imgR=%d\n",imgL,imgR);
    
    winL = 0;
    winR = win_size - 1;
    
    if(imgL < 0)
    {
        //some portion of the left will be blank
        winL = floor(-(double)imgL / imgW * win_size);
        imgL = 0;
        //printf("winL=%d,imgL=%d\n",winL,imgL);
    }
    
    if(imgR >= (int)img_size)
    {
        //some portion of the right will be blank
        winR = win_size - 1 - floor(((double)imgR - img_size + 1.0) / imgW * win_size);
        imgR = img_size - 1;
        //printf("winR=%d,imgR=%d\n",winR,imgR);
    }
    
    img->y = imgL;
    img->h = imgR - imgL + 1;

    win->y = winL;
    win->h = winR - winL + 1;
}
