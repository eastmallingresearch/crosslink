/*
build using make_viewer.sh script, run from laptop to link appropriate SDL libs
*/

#include "gg_utils.h"
#include "gg_ga.h"
#include "gg_gibbs.h"
#include "rjv_cutils.h"

#include <SDL2/SDL.h>

#define setpixelrgb(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))

void show_info(struct conf*c,int offset)
{
    struct marker*m=NULL;
    m = c->array[offset];
    
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

void show_rf_lod(struct conf*c,int xoff,int yoff)
{
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    unsigned x,R,N,S;
    double rf,s,lod;
    
    m1 = c->array[xoff];
    m2 = c->array[yoff];

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

uint32_t*generate_image(struct conf*c,double minlod)
{
    uint32_t*buff=NULL;
    unsigned i,j,x,R,N,S,val[3],val2[3],tmpval;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    double rf,s,lod;
    
    //pixel buffer
    assert(buff = calloc(c->nmarkers*c->nmarkers,sizeof(uint32_t)));
    
    printf("generating...\n");
    for(i=0; i<c->nmarkers; i++)
    {
        m1 = c->array[i];
        for(j=i; j<c->nmarkers; j++)
        {
            m2 = c->array[j];
            
            val[2] = 0;
            
            //generate checkerboard pattern denoting linkage group boundaries
            //in the blue channel of the "LOD" part of the graph
            if((m1->lg & 0x1) ^ (m2->lg & 0x1)) val2[2] = 64;
            else                                val2[2] = 0;
            
            //for LM vs NP comparisions, compare the information anyway
            //strong linkage will indicate we likely have an error in the marker typing
            //display as yellow (otherwise it's just always black)
            if((m1->type == LMTYPE && m2->type == NPTYPE) || (m1->type == NPTYPE && m2->type == LMTYPE))
            {
                if(m1->type == LMTYPE) calc_RN_simple2(c,m1,m2,0,1,&R,&N);
                else                   calc_RN_simple2(c,m1,m2,1,0,&R,&N);

                val[0] = val[1] = 0;
                val2[0] = val2[1] = 0;
                if(N > 0)
                {
                    rf = (double)R / N;
                    if(rf <= 0.5)
                    {
                        //coupling linkage, yellow
                        val[0] = val[1] = (0.5 - rf) * 2.0 * 255.999;
                    }
                    else
                    {
                        //repulsion linkage, blue
                        val[2] = (rf - 0.5) * 2.0 * 255.999;
                    }
                    
                    //calculate linkage LOD
                    s = 1.0 - rf;
                    S = N - R;
                    
                    lod = 0.0;
                    if(s > 0.0) lod += S * log10(2.0*s);
                    if(rf > 0.0) lod += R * log10(2.0*rf);
                    
                    if(lod >= minlod) val2[0] = val2[1] = tanh(lod/50.0) * 255.999;
                }
            }
            else
            {
                for(x=0; x<2; x++)
                {
                    val[x] = 0;
                    val2[x] = 0;
                    if(m1->data[x] && m2->data[x])
                    {
                        calc_RN_simple(c,m1,m2,x,&R,&N);
                        if(N > 0)
                        {
                            rf = (double)R / N;
                            if(rf <= 0.5)
                            {
                                //coupling linkage, red or green
                                val[x] = (0.5 - rf) * 2.0 * 255.999;
                            }
                            else
                            {
                                //repulsion linkage, blue
                                //indicate the strongest repulsion value of the two
                                tmpval = (rf - 0.5) * 2.0 * 255.999;
                                if(val[2] < tmpval) val[2] = tmpval;
                            }
                            
                            //calculate linkage LOD
                            s = 1.0 - rf;
                            S = N - R;
                            
                            lod = 0.0;
                            if(s > 0.0) lod += S * log10(2.0*s);
                            if(rf > 0.0) lod += R * log10(2.0*rf);
                            
                            if(lod >= minlod) val2[x] = tanh(lod/50.0) * 255.999;
                        }
                    }
                }
            }
            
            //buff[y*width+x] = (r<<16)+(g<<8)+b;
            setpixelrgb(buff,i,j,c->nmarkers,val[0],val[1],val[2]);//rf
            if(i!=j) setpixelrgb(buff,j,i,c->nmarkers,val2[0],val2[1],val2[2]);//lod
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
void calc_view(unsigned img_size,unsigned win_size,double img_centre,double img_width,SDL_Rect*img,SDL_Rect*win)
{
    int winL,winR,imgL,imgR,imgW;
    
    imgL = floor((double)img_centre - img_width / 2.0);
    imgR = floor((double)img_centre + img_width / 2.0 - 0.00001);
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
    
    img->x = img->y = imgL;
    img->w = img->h = imgR - imgL + 1;

    win->x = win->y = winL;
    win->w = win->h = winR - winL + 1;
}

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    SDL_Rect src,dst;
    unsigned size;
    unsigned hardware,skip_markers,total_markers;
    double minlod,base_pix,width_pix;
    int mx,my,markerx,markery;
    uint32_t*buff=NULL;
    

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parseuns(argc,argv,"window_size",&size,1,1000);
    parsedbl(argc,argv,"minlod",&minlod,1,3.0);
    //parseuns(argc,argv,"phased",&c->view_phased,1,1);
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,1);
    parseuns(argc,argv,"hardware_accel",&hardware,1,1);
    parseuns(argc,argv,"skip",&skip_markers,1,0);   //load starting from the first marker
    parseuns(argc,argv,"total",&total_markers,1,0); //zero indicates load all markers
    parseend(argc,argv);
    
    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load phased marker data from all lgs
    load_phased_all(c,c->inp,skip_markers,total_markers);
    
    //render image from the rflod data
    buff = generate_image(c,minlod);
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    assert(win = SDL_CreateWindow("rflod viewer",0,0,size,size,SDL_WINDOW_SHOWN));
    
    if(hardware) assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED));
    else         assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); //"linear" or "nearest"
    //assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING, c->nmarkers, c->nmarkers));
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STATIC, c->nmarkers, c->nmarkers));
    SDL_UpdateTexture(tex, NULL, buff, c->nmarkers * sizeof (uint32_t));
    
    base_pix = (double)c->nmarkers / 2.0;      //control view window
    width_pix = (double)c->nmarkers;

    while(1)
    {
        calc_view(c->nmarkers,size,base_pix,width_pix,&src,&dst);
        
        //SDL_UpdateTexture(tex, NULL, buff, c->nmarkers * sizeof (uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, &dst);
        SDL_RenderPresent(ren);
        
        SDL_WaitEvent(&eve);

        //quit - press q, escape or close button on window
        if(eve.type == SDL_QUIT) break;
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_q) break;
            if(eve.key.keysym.sym == SDLK_ESCAPE) exit(1);
        }

        //show whole map
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_RETURN || eve.key.keysym.sym == SDLK_RETURN2)
            {
                base_pix = (double)c->nmarkers / 2.0;      //reset view window
                width_pix = (double)c->nmarkers;
            }
        }
        
        //pan and zoom
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_UP)
            {
                width_pix /= (double)1.02;
            }
            if(eve.key.keysym.sym == SDLK_DOWN)
            {
                width_pix *= (double)1.02;
            }
            if(eve.key.keysym.sym == SDLK_LEFT)
            {
                base_pix -= 0.02 * width_pix;
            }
            if(eve.key.keysym.sym == SDLK_RIGHT)
            {
                base_pix += 0.02 * width_pix;
            }
        }
        
        //update window title to show marker info
        if(eve.type == SDL_MOUSEBUTTONDOWN)
        {
            mx = eve.button.x;
            my = eve.button.y;
            which_markers(mx,my,&src,&dst,&markerx,&markery);
            
            /*printf("mouse=(%d,%d) marker=(%d,%d)\n",mx,my,markerx,markery);
            printf("img=(%d+%d,%d+%d)\n",src.x,src.w,src.y,src.h);
            printf("win=(%d+%d,%d+%d)\n",dst.x,dst.w,dst.y,dst.h);*/

            printf("Xaxis: ");
            if(markerx != -1) show_info(c,markerx);
            printf("Yaxis: ");
            if(markery != -1) show_info(c,markery);
            printf("Comp: ");
            if(markerx != -1 && markery != -1) show_rf_lod(c,markerx,markery);
            printf("\n");
        }
    }

    SDL_Quit();

    return 0;
}
