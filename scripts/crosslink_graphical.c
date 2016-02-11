#include "crosslink_viewer.h"
#include "crosslink_utils.h"

/*void show_info(struct lg*p,int offset)
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
}*/


uint32_t*generate_graphical(struct conf*c,struct lg*p,unsigned type)
{
    uint32_t*buff=NULL;
    unsigned i,j,x,rgb[3];
    struct marker*m=NULL;
    VARTYPE*data=NULL;
    unsigned itype,iphased;
    
    itype = type % 3;
    iphased = type / 3;
    
    //pixel buffer
    assert(buff = calloc(p->nmarkers*c->nind,sizeof(uint32_t)));
    
    printf("generating...\n");
    for(i=0; i<p->nmarkers; i++)
    {
        m = p->array[i];
        
        for(j=0; j<c->nind; j++)
        {
            rgb[0] = 0;
            rgb[1] = 0;
            rgb[2] = 0;
            
            for(x=0; x<2; x++)
            {
                if(iphased) data = m->data[x]; //phased
                else        data = m->orig[x]; //unphased

                if(itype == 0 && x == 1) continue; //mat only
                if(itype == 1 && x == 0) continue; //pat only
            
                if(data != NULL)
                {
                    //generate checkerboard pattern denoting linkage group boundaries
                    //in the blue channel of the "LOD" part of the graph
                    //if((m1->lg & 0x1) ^ (m2->lg & 0x1)) val2[2] = 64;
                    //else                                val2[2] = 0;

                    if(data[j] == MISSING)
                    {
                        rgb[0] = 127;
                        rgb[1] = 127;
                        rgb[2] = 127;
                    }
                    else if(data[j] == 1)
                    {
                        rgb[x] = 255;
                    }
                }
            }
            
            setpixelrgb(buff,i,j,p->nmarkers,rgb[0],rgb[1],rgb[2]);
        }
    }
    
    printf("done\n");
    
    return buff;
}

/*void which_markers(int mx,int my,SDL_Rect*img,SDL_Rect*win,int*imgx,int*imgy)
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
}*/

//calc which rectangle of image to blit to which rectangle in the window
void calc_graphical(unsigned img_sizex,unsigned img_sizey,unsigned win_sizex,unsigned win_sizey,
                    double img_centrex,double img_centrey,double img_widthx,double img_widthy,
                    SDL_Rect*img,SDL_Rect*win)
{
    int winL,winR,imgL,imgR,imgW;
    
    imgL = floor((double)img_centrex - img_widthx / 2.0);
    imgR = floor((double)img_centrex + img_widthx / 2.0 - 0.00001);
    imgW = imgR - imgL + 1;
    
    //printf("imgL=%d, imgR=%d\n",imgL,imgR);
    
    winL = 0;
    winR = win_sizex - 1;
    
    if(imgL < 0)
    {
        //some portion of the left will be blank
        winL = floor(-(double)imgL / imgW * win_sizex);
        imgL = 0;
        //printf("winL=%d,imgL=%d\n",winL,imgL);
    }
    
    if(imgR >= (int)img_sizex)
    {
        //some portion of the right will be blank
        winR = win_sizex - 1 - floor(((double)imgR - img_sizex + 1.0) / imgW * win_sizex);
        imgR = img_sizex - 1;
        //printf("winR=%d,imgR=%d\n",winR,imgR);
    }
    
    img->x = imgL;
    img->w = imgR - imgL + 1;

    win->x = winL;
    win->w = winR - winL + 1;

    imgL = floor((double)img_centrey - img_widthy / 2.0);
    imgR = floor((double)img_centrey + img_widthy / 2.0 - 0.00001);
    imgW = imgR - imgL + 1;
    
    //printf("imgL=%d, imgR=%d\n",imgL,imgR);
    
    winL = 0;
    winR = win_sizey - 1;
    
    if(imgL < 0)
    {
        //some portion of the left will be blank
        winL = floor(-(double)imgL / imgW * win_sizey);
        imgL = 0;
        //printf("winL=%d,imgL=%d\n",winL,imgL);
    }
    
    if(imgR >= (int)img_sizey)
    {
        //some portion of the right will be blank
        winR = win_sizey - 1 - floor(((double)imgR - img_sizey + 1.0) / imgW * win_sizey);
        imgR = img_sizey - 1;
        //printf("winR=%d,imgR=%d\n",winR,imgR);
    }
    
    img->y = imgL;
    img->h = imgR - imgL + 1;

    win->y = winL;
    win->h = winR - winL + 1;
}
