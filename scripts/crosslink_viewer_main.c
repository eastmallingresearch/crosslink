/*
build using make_viewer.sh script, run from laptop to link appropriate SDL libs
*/

#include "gg_utils.h"
#include "gg_ga.h"
#include "gg_gibbs.h"
#include "rjv_cutils.h"

#include <SDL2/SDL.h>

#define setpixelrgb(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
   
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    SDL_Rect src;
    unsigned size,i,j,x,R,N,S,val[3],val2[3],tmpval;
    unsigned hardware;
    struct marker*m1=NULL;
    struct marker*m2=NULL;
    double rf,s,lod,minlod;
    
    double base_pix;
    double width_pix;
    
    uint32_t*buff=NULL;

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&c->inp,0,NULL);
    parseuns(argc,argv,"window_size",&size,1,500);
    parsedbl(argc,argv,"minlod",&minlod,1,3.0);
    parseuns(argc,argv,"phased",&c->view_phased,1,1);
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,1);
    parseuns(argc,argv,"hardware_accel",&hardware,1,1);
    parseend(argc,argv);
    
    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load phased marker data from all lgs
    load_phased_all(c,c->inp);
    
    base_pix = (double)c->nmarkers / 2.0;      //control view window
    width_pix = c->nmarkers;
    
    //pixel buffer
    assert(buff = calloc(c->nmarkers*c->nmarkers,sizeof(uint32_t)));
    
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
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    assert(win = SDL_CreateWindow("rflod viewer",0,0,size,size,SDL_WINDOW_SHOWN));
    
    if(hardware) assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED));
    else         assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); //"linear" or "nearest"
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING, c->nmarkers, c->nmarkers));
    
    while(1)
    {
        src.x = base_pix - width_pix / 2.0;
        src.y = base_pix - width_pix / 2.0;
        src.w = width_pix;
        src.h = width_pix;
        
        SDL_UpdateTexture(tex, NULL, buff, c->nmarkers * sizeof (uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, NULL);
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
                base_pix = (double)c->nmarkers / 2.0;
                width_pix = c->nmarkers;
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
    }

    SDL_Quit();

    return 0;
}
