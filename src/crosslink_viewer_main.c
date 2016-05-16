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

this version aims to support phased and unphased data using the new generic load functions
*/

#include "crosslink_utils.h"
#include "crosslink_ga.h"
#include "crosslink_gibbs.h"
#include "crosslink_viewer.h"
#include "rjvparser.h"

#include <unistd.h>

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    struct lg*p=NULL;
    SDL_Surface* surface = NULL;
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    SDL_Rect src,dst;
    unsigned size,pos;
    unsigned hardware,skip,total;
    char*inp=NULL;
    char*datatype=NULL;
    char*named=NULL;
    char execpath[1000];
    char*pexec=NULL;
    int retcode=-1;

    //double minlod;
    double xbase_pix,ybase_pix,width_pix;
    int mx,my,markerx,markery;
    uint32_t*buff_mat=NULL;
    uint32_t*buff_pat=NULL;
    uint32_t*buff_com=NULL;

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    rjvparser("inp|STRING|!|input genotype file(s)",&inp);
    rjvparser("window_size|UNSIGNED|1000|window size (pixels)",&size);
    rjvparser("datatype|STRING|imputed|state of the genotype data: imputed, phased, unphased",&datatype);
    rjvparser("bitstrings|UNSIGNED|1|1=use bitstring representation of the data internally",&c->gg_bitstrings);
    rjvparser("hardware|UNSIGNED|0|1=use hardware graphical acceleration when available",&hardware);
    rjvparser("skip|UNSIGNED|0|how many markers to skip at the start of the genotype file",&skip);   //load starting from the first marker
    rjvparser("total|UNSIGNED|0|how many markers to load in total, 0=load all",&total); //zero indicates load all markers
    rjvparser("marker|STRING|-|named marker to centre intial view on",&named);//named marker
    rjvparser2(argc,argv,rjvparser(0,0),"Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details\npresents a graphical view of linkage LOD and map distances\n\nControl keys:\nCURSOR KEYS  = pan\n+/-          = zoom\nENTER        = recentre\nm,p,c        = maternal,paternal,combined mode\nq,escape,0-9 = quit with various bash exit codes ($?)");

    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load all data from multiple files, treat as a single lg
    p = noheader_merged(c,inp,skip,total);

    //convert to phased / unphased, imputed / unimputed form
    //and compress to bitstrings
         if(strcmp(datatype,"unphased") == 0) generic_convert_to_unphased(c,p);
    else if(strcmp(datatype,"phased") == 0)   generic_convert_to_phased(c,p);
    else if(strcmp(datatype,"imputed") == 0)  generic_convert_to_imputed(c,p);
    else                                      assert(0);

    //render images from the rflod data
    buff_com = generate_image(c,p,0); //combined info
    buff_mat = generate_image(c,p,1); //maternal only
    buff_pat = generate_image(c,p,2); //paternal only

    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }

    IMG_Init(IMG_INIT_PNG);
    assert(win = SDL_CreateWindow(inp,0,0,size,size,SDL_WINDOW_SHOWN));

    //work out path to icon
    assert(readlink("/proc/self/exe", execpath, 998) != -1);
    assert((pexec=strrchr(execpath,'/')) != NULL);
    strcpy(pexec,"/icon.png");
    //printf("icon file: %s\n",execpath);

    //load and set icon
    assert((surface = IMG_Load(execpath)) != NULL);
    SDL_SetWindowIcon(win, surface);

    if(hardware) assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED));
    else         assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "nearest"); //"linear" or "nearest"
    //assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING, c->nmarkers, c->nmarkers));
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STATIC, p->nmarkers, p->nmarkers));
    SDL_UpdateTexture(tex, NULL, buff_com, p->nmarkers * sizeof (uint32_t));

    xbase_pix = ybase_pix = (double)p->nmarkers / 2.0;      //control view window
    width_pix = (double)p->nmarkers;

    if(named!= NULL)
    {
        //centre initial view on named marker
        pos = find_marker(p,named);
        
        if(pos < p->nmarkers)
        {
            xbase_pix = ybase_pix = (double)pos + 0.5;
            width_pix = (double)15.0;
        }
    }

    while(retcode == -1)
    {
        calc_view(p->nmarkers,size,xbase_pix,ybase_pix,width_pix,&src,&dst);
        
        //SDL_UpdateTexture(tex, NULL, buff, c->nmarkers * sizeof (uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, &dst);
        SDL_RenderPresent(ren);
        
        SDL_WaitEvent(&eve);

        switch(eve.type)
        {
            case SDL_QUIT:
                //window closed
                retcode = 0;
                break;

            case SDL_MOUSEBUTTONDOWN:
                //mouse click - show info on markers
                mx = eve.button.x;
                my = eve.button.y;
                which_markers(mx,my,&src,&dst,&markerx,&markery);
                
                /*printf("mouse=(%d,%d) marker=(%d,%d)\n",mx,my,markerx,markery);
                printf("img=(%d+%d,%d+%d)\n",src.x,src.w,src.y,src.h);
                printf("win=(%d+%d,%d+%d)\n",dst.x,dst.w,dst.y,dst.h);*/

                printf("Xaxis: ");
                if(markerx != -1) show_info(p,markerx);
                printf("Yaxis: ");
                if(markery != -1) show_info(p,markery);
                printf("Comp: ");
                if(markerx != -1 && markery != -1) show_rf_lod(c,p,markerx,markery);
                printf("\n");
                break;

            case SDL_KEYDOWN:
                switch(eve.key.keysym.sym)
                {
                    case SDLK_q:
                        retcode = 0;
                        break;
                    case SDLK_ESCAPE:
                        retcode = 100;
                        break;
                    case SDLK_0:
                        retcode = 10;
                        break;
                    case SDLK_1:
                        retcode = 11;
                        break;
                    case SDLK_2:
                        retcode = 12;
                        break;
                    case SDLK_3:
                        retcode = 13;
                        break;
                    case SDLK_4:
                        retcode = 14;
                        break;
                    case SDLK_5:
                        retcode = 15;
                        break;
                    case SDLK_6:
                        retcode = 16;
                        break;
                    case SDLK_7:
                        retcode = 17;
                        break;
                    case SDLK_8:
                        retcode = 18;
                        break;
                    case SDLK_9:
                        retcode = 19;
                        break;
                    case SDLK_RETURN:
                    case SDLK_RETURN2:
                        xbase_pix = ybase_pix = (double)p->nmarkers / 2.0;      //reset view window
                        width_pix = (double)p->nmarkers;
                        break;
                    case SDLK_c:
                        //combined view
                        SDL_UpdateTexture(tex, NULL, buff_com, p->nmarkers * sizeof (uint32_t));
                        break;
                    case SDLK_m:
                        //maternal view
                        SDL_UpdateTexture(tex, NULL, buff_mat, p->nmarkers * sizeof (uint32_t));
                        break;
                    case SDLK_p:
                        //paternal view
                        SDL_UpdateTexture(tex, NULL, buff_pat, p->nmarkers * sizeof (uint32_t));
                        break;
                    case SDLK_KP_PLUS:
                    case SDLK_PLUS:
                    case SDLK_EQUALS:
                        //zoom in
                        width_pix /= (double)1.02;
                        break;
                    case SDLK_KP_MINUS:
                    case SDLK_MINUS:
                        //zoom out
                        width_pix *= (double)1.02;
                        break;
                    case SDLK_UP:
                        ybase_pix -= 0.02 * width_pix;
                        break;
                    case SDLK_DOWN:
                        ybase_pix += 0.02 * width_pix;
                        break;
                    case SDLK_LEFT:
                        xbase_pix -= 0.02 * width_pix;
                        break;
                    case SDLK_RIGHT:
                        xbase_pix += 0.02 * width_pix;
                        break;

                    default:
                        break;
                }
                
                break;
            default:
                break;
        }
    }

    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_FreeSurface(surface);
    SDL_DestroyWindow(win);
    free(buff_mat);
    free(buff_pat);
    free(buff_com);
    SDL_Quit();

    return retcode;
}
