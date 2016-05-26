//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
//
// test SDL2
//

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <SDL2/SDL.h>
//#include <inttypes.h>

#define setpixelrgb(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))
#define setpixelc(buff,x,y,w,c) ((buff)[(y)*(w)+(x)] = (c))
#define WHITE ((255<<16)+(255<<8)+255)

int main(int argc, char**argv)
{
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    SDL_Rect src;
    
    unsigned nmarkers = 3000;
    unsigned nlgs=10;
    unsigned lgsize[] = {200,300,400,200,300,400,250,350,250,350};
    unsigned size = nmarkers + nlgs - 1; //one pixel per marker plus lg boundaries

    int winsize=1000;          //window size in pixels (always square)
    unsigned i,r,g,b,x,y;
    double base_pix = (double)size / 2.0;      //control view window
    double width_pix = size;
    
    uint32_t*buff=NULL;
    
    srand(time(NULL));
    
    assert(buff = calloc(size*size,sizeof(uint32_t)));
    
    //draw dividing lines between lgs
    /*x = 0;
    for(i=0; i<nlgs-1; i++)
    {
        x += lgsize[i];
        for(y=0; y<size; y++)
        {
            setpixelc(buff,x,y,size,WHITE);
            setpixelc(buff,y,x,size,WHITE);
        }
    }*/
    
    for(x=0; x<size; x++)
    {
        for(y=0; y<size; y++)
        {
            r = x % 256;
            g = y % 256;     //i / 256;
            b = 0;           //rand() % 256;
            //buff[y*width+x] = (r<<16)+(g<<8)+b;
            setpixelrgb(buff,x,y,size,r,g,b);
        }
    }
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    assert(win = SDL_CreateWindow("Hello World!",0,0,winsize,winsize,SDL_WINDOW_SHOWN));
    assert(ren = SDL_CreateRenderer(win, -1, 0));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear"); //"linear" or "nearest"
    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING, size, size));
    
    while(1)
    {
        src.x = base_pix - width_pix / 2.0;
        src.y = base_pix - width_pix / 2.0;
        src.w = width_pix;
        src.h = width_pix;
        
        SDL_UpdateTexture(tex, NULL, buff, size * sizeof (uint32_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, NULL);
        SDL_RenderPresent(ren);
        
        SDL_WaitEvent(&eve);

        //quit - press q, escape or close button on window
        if(eve.type == SDL_QUIT) break;
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_q) break;
            if(eve.key.keysym.sym == SDLK_ESCAPE) break;
        }

        //show whole map
        if(eve.type == SDL_KEYDOWN)
        {
            if(eve.key.keysym.sym == SDLK_RETURN || eve.key.keysym.sym == SDLK_RETURN2)
            {
                base_pix = (double)size / 2.0;
                width_pix = size;
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
