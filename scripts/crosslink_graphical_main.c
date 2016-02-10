/*
build using make_viewer.sh script, run from laptop to link appropriate SDL libs

view markers in map order
*/

#include "gg_utils.h"
#include "gg_ga.h"
#include "gg_gibbs.h"
#include "crosslink_graphical.h"
#include "crosslink_viewer.h"
#include "rjv_cutils.h"

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
    parsestr(argc,argv,"inp",&inp,0,NULL);
    parseuns(argc,argv,"sizex",&sizex,1,1000);
    parseuns(argc,argv,"sizey",&sizey,1,1000);
    parsestr(argc,argv,"datatype",&datatype,1,"imputed");
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,1);
    parseuns(argc,argv,"hardware",&hardware,1,1);
    parseuns(argc,argv,"skip",&skip,1,0);   //load starting from the first marker
    parseuns(argc,argv,"total",&total,1,0); //zero indicates load all markers
    parseend(argc,argv);
    
    //precalc bitmasks for every possible bit position
    init_masks(c);

    //load all data from file, treat as a single lg
    p = generic_load_merged(c,inp,skip,total);
    
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
            if(eve.key.keysym.sym == SDLK_z)
            {
                iphased = !iphased;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_m)
            {
                itype = 0;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_p)
            {
                itype = 1;
                ibuff = itype + 3 * iphased;
                SDL_UpdateTexture(tex, NULL, buff[ibuff], p->nmarkers * sizeof (uint32_t));
            }
            if(eve.key.keysym.sym == SDLK_b)
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
