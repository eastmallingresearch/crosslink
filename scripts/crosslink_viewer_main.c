/*
build using make_viewer.sh script, run from laptop to link appropriate SDL libs

this version aims to support phased and unphased data using the new generic load functions
*/

#include "crosslink_utils.h"
#include "crosslink_ga.h"
#include "crosslink_gibbs.h"
#include "crosslink_viewer.h"
#include "rjv_cutils.h"

int main(int argc,char*argv[])
{
    struct conf*c=NULL;
    struct lg*p=NULL;
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
    
    double minlod,xbase_pix,ybase_pix,width_pix;
    int mx,my,markerx,markery;
    uint32_t*buff=NULL;

    /*parse command line options*/
    assert(c = calloc(1,sizeof(struct conf)));
    parsestr(argc,argv,"inp",&inp,0,NULL);
    parseuns(argc,argv,"window_size",&size,1,1000);
    parsedbl(argc,argv,"minlod",&minlod,1,3.0);
    parsestr(argc,argv,"datatype",&datatype,1,"imputed");
    parseuns(argc,argv,"bitstrings",&c->gg_bitstrings,1,1);
    parseuns(argc,argv,"hardware",&hardware,1,1);
    parseuns(argc,argv,"skip",&skip,1,0);   //load starting from the first marker
    parseuns(argc,argv,"total",&total,1,0); //zero indicates load all markers
    parsestr(argc,argv,"marker",&named,1,"NONE");//named marker
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
    
    //render image from the rflod data
    buff = generate_image(c,p,minlod);
    
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
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STATIC, p->nmarkers, p->nmarkers));
    SDL_UpdateTexture(tex, NULL, buff, p->nmarkers * sizeof (uint32_t));
    
    xbase_pix = ybase_pix = (double)p->nmarkers / 2.0;      //control view window
    width_pix = (double)p->nmarkers;
    
    if(strcmp(named,"NONE") != 0)
    {
        //centre initial view on named marker
        pos = find_marker(p,named);
        
        if(pos < p->nmarkers)
        {
            xbase_pix = ybase_pix = (double)pos + 0.5;
            width_pix = (double)15.0;
        }
    }

    while(1)
    {
        calc_view(p->nmarkers,size,xbase_pix,ybase_pix,width_pix,&src,&dst);
        
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
                xbase_pix = ybase_pix = (double)p->nmarkers / 2.0;      //reset view window
                width_pix = (double)p->nmarkers;
            }
        }
        
        //pan and zoom
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_KP_PLUS || eve.key.keysym.sym == SDLK_PLUS  || eve.key.keysym.sym == SDLK_EQUALS)
            {
                width_pix /= (double)1.02;
            }
            if(eve.key.keysym.sym == SDLK_KP_MINUS || eve.key.keysym.sym == SDLK_MINUS)
            {
                width_pix *= (double)1.02;
            }
            if(eve.key.keysym.sym == SDLK_UP)
            {
                ybase_pix -= 0.02 * width_pix;
            }
            if(eve.key.keysym.sym == SDLK_DOWN)
            {
                ybase_pix += 0.02 * width_pix;
            }
            if(eve.key.keysym.sym == SDLK_LEFT)
            {
                xbase_pix -= 0.02 * width_pix;
            }
            if(eve.key.keysym.sym == SDLK_RIGHT)
            {
                xbase_pix += 0.02 * width_pix;
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
            if(markerx != -1) show_info(p,markerx);
            printf("Yaxis: ");
            if(markery != -1) show_info(p,markery);
            printf("Comp: ");
            if(markerx != -1 && markery != -1) show_rf_lod(c,p,markerx,markery);
            printf("\n");
        }
    }

    SDL_Quit();

    return 0;
}
