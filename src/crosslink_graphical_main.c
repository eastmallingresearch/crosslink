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
build using make_viewer.sh script, run from laptop to link appropriate SDL libs

view markers in map order
*/

#include "crosslink_utils.h"
#include "crosslink_ga.h"
#include "crosslink_gibbs.h"
#include "crosslink_graphical.h"
#include "crosslink_viewer.h"
#include "rjvparser.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    SDL_Rect src,dst;
    unsigned sizex,sizey;
    unsigned hardware,skip,total;
    struct lg*p=NULL;
    char*inp=NULL;
    char*datatype=NULL;
    
    double xbase_pix,ybase_pix,xwidth_pix,ywidth_pix;
    int mx,my;
    //int markerx,markery;
    uint32_t*buff[6];
    unsigned ibuff;
    unsigned iphased=1;
    unsigned itype=2,i;

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    rjvparser("inp|STRING|!|input genotype file",&inp);
    rjvparser("sizex|UNSIGNED|1000|window width (pixels)",&sizex);
    rjvparser("sizey|UNSIGNED|1000|window height (pixels)",&sizey);
    rjvparser("datatype|STRING|imputed|state of the genotype data: imputed, phased, unphased",&datatype);
    rjvparser("bitstrings|UNSIGNED|1|1=use bitstring representation of the data internally",&c->gg_bitstrings);
    rjvparser("hardware|UNSIGNED|0|1=use hardware graphical acceleration when available",&hardware);
    rjvparser("skip|UNSIGNED|0|how many markers to skip at the start of the genotype file",&skip);   //load starting from the first marker
    rjvparser("total|UNSIGNED|0|how many markers to load in total, 0=load all",&total); //zero indicates load all markers
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\npresents a graphical view of the sample genotypes in their current order");
    
    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load all data from file, treat as a single lg
    //p = generic_load_merged(c,inp,skip,total);
    p = noheader_merged(c,inp,skip,total);
    
    //convert to phased / unphased, imputed / unimputed form
    //and compress to bitstrings
    if(strcmp(datatype,"unphased") == 0)     generic_convert_to_unphased(c,p);
    else if(strcmp(datatype,"phased") == 0)  generic_convert_to_phased(c,p);
    else if(strcmp(datatype,"imputed") == 0) generic_convert_to_imputed(c,p);
    else                                     assert(0);
    
    //render images showing the different representations
    for(i=0; i<6; i++) buff[i] = generate_graphical(c,p,i);
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    assert(win = SDL_CreateWindow("genotype viewer",0,0,sizex,sizey,SDL_WINDOW_SHOWN));
    
    if(hardware) assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED));
    else         assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); //"linear" or "nearest"
    
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STATIC, p->nmarkers, c->nind));//SDL_TEXTUREACCESS_STREAMING
    ibuff = itype + 3 * iphased;
    SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
    
    xbase_pix = (double)p->nmarkers / 2.0;      //control view window
    ybase_pix = (double)c->nind / 2.0;          //control view window
    xwidth_pix = (double)p->nmarkers;
    ywidth_pix = (double)c->nind;

    while(1)
    {
        calc_graphical(p->nmarkers,c->nind, //image size (pixels)
                       sizex,sizey,//window size (pixels)
                       xbase_pix,ybase_pix,xwidth_pix,ywidth_pix, //view position and size
                       &src,&dst);
        
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, &dst);
        SDL_RenderPresent(ren);
        
        SDL_WaitEvent(&eve);

        //quit - press q, escape or close button on window
        if(eve.type == SDL_QUIT) break;
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_q) break;
            if(eve.key.keysym.sym == SDLK_ESCAPE) {SDL_Quit();exit(100);}
            if(eve.key.keysym.sym == SDLK_0) {SDL_Quit();exit(10);}
            if(eve.key.keysym.sym == SDLK_1) {SDL_Quit();exit(11);}
            if(eve.key.keysym.sym == SDLK_2) {SDL_Quit();exit(12);}
            if(eve.key.keysym.sym == SDLK_3) {SDL_Quit();exit(13);}
            if(eve.key.keysym.sym == SDLK_4) {SDL_Quit();exit(14);}
            if(eve.key.keysym.sym == SDLK_5) {SDL_Quit();exit(15);}
            if(eve.key.keysym.sym == SDLK_6) {SDL_Quit();exit(16);}
            if(eve.key.keysym.sym == SDLK_7) {SDL_Quit();exit(17);}
            if(eve.key.keysym.sym == SDLK_8) {SDL_Quit();exit(18);}
            if(eve.key.keysym.sym == SDLK_9) {SDL_Quit();exit(19);}
        }

        //show whole map
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_RETURN || eve.key.keysym.sym == SDLK_RETURN2)
            {
                xbase_pix = (double)p->nmarkers / 2.0;      //control view window
                ybase_pix = (double)c->nind / 2.0;          //control view window
                xwidth_pix = (double)p->nmarkers;
                ywidth_pix = (double)c->nind;
            }
            
            //which between phased and phased view
            if(eve.key.keysym.sym == SDLK_z) //toggle phase information
            {
                iphased = !iphased;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_m) //switch to maternal view
            {
                itype = 0;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_p) //switch to paternal view
            {
                itype = 1;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_c) //switch to combined view
            {
                itype = 2;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
        }
        
        //pan and zoom
        if(eve.type == SDL_KEYDOWN)
        {
            //shift + cursor key => zoom
            if(eve.key.keysym.mod & KMOD_SHIFT)
            {
                if(eve.key.keysym.sym == SDLK_UP)
                {
                    ywidth_pix /= (double)1.02;
                }
                if(eve.key.keysym.sym == SDLK_DOWN)
                {
                    ywidth_pix *= (double)1.02;
                }
                if(eve.key.keysym.sym == SDLK_LEFT)
                {
                    xwidth_pix /= (double)1.02;
                }
                if(eve.key.keysym.sym == SDLK_RIGHT)
                {
                    xwidth_pix *= (double)1.02;
                }
            }
            //cursor key => pan, +/- => zoom both axes
            else
            {    
                if(eve.key.keysym.sym == SDLK_KP_PLUS || eve.key.keysym.sym == SDLK_PLUS  || eve.key.keysym.sym == SDLK_EQUALS)
                {
                    xwidth_pix /= (double)1.02;
                    ywidth_pix /= (double)1.02;
                }
                if(eve.key.keysym.sym == SDLK_KP_MINUS || eve.key.keysym.sym == SDLK_MINUS)
                {
                    xwidth_pix *= (double)1.02;
                    ywidth_pix *= (double)1.02;
                }
                if(eve.key.keysym.sym == SDLK_UP)
                {
                    ybase_pix -= 0.02 * ywidth_pix;
                }
                if(eve.key.keysym.sym == SDLK_DOWN)
                {
                    ybase_pix += 0.02 * ywidth_pix;
                }
                if(eve.key.keysym.sym == SDLK_LEFT)
                {
                    xbase_pix -= 0.02 * xwidth_pix;
                }
                if(eve.key.keysym.sym == SDLK_RIGHT)
                {
                    xbase_pix += 0.02 * xwidth_pix;
                }
            }
        }
        
        //update window title to show marker info
        if(eve.type == SDL_MOUSEBUTTONDOWN)
        {
            assert(mx = eve.button.x);
            assert(my = eve.button.y);
            //which_markers(mx,my,&src,&dst,&markerx,&markery);
            
            /*printf("mouse=(%d,%d) marker=(%d,%d)\n",mx,my,markerx,markery);
            printf("img=(%d+%d,%d+%d)\n",src.x,src.w,src.y,src.h);
            printf("win=(%d+%d,%d+%d)\n",dst.x,dst.w,dst.y,dst.h);*/

            /*printf("Xaxis: ");
            if(markerx != -1) show_info(p,markerx);
            printf("Yaxis: ");
            if(markery != -1) show_info(p,markery);
            printf("Comp: ");
            if(markerx != -1 && markery != -1) show_rf_lod(c,p,markerx,markery);
            printf("\n");*/
        }
    }

    SDL_Quit();

    return 0;
}
