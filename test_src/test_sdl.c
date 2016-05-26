//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
//
// test SDL2
//

#include <stdio.h>
#include <assert.h>
#include <SDL2/SDL.h>

int main(int argc, char**argv)
{
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Surface* bmp = NULL;
    SDL_Texture* tex = NULL;
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    //assert(win = SDL_CreateWindow("Hello World!", 100, 100, 640, 480, SDL_WINDOW_SHOWN));
    //assert(ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC));
    assert(win = SDL_CreateWindow("Hello World!",
                                  SDL_WINDOWPOS_UNDEFINED,SDL_WINDOWPOS_UNDEFINED,
                                  0, 0,
                                  SDL_WINDOW_FULLSCREEN_DESKTOP));
    assert(ren = SDL_CreateRenderer(win, -1, 0));
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear"); //"linear" or "nearest"
    
    assert(bmp = SDL_LoadBMP("hello.bmp"));
    assert(tex = SDL_CreateTextureFromSurface(ren, bmp));
    SDL_FreeSurface(bmp);
    SDL_RenderClear(ren);
    SDL_RenderCopy(ren, tex, NULL, NULL);
    SDL_RenderPresent(ren);
    //SDL_RenderClear(ren);
    //SDL_RenderCopy(ren, tex, NULL, NULL);
    //SDL_RenderPresent(ren);
    SDL_Delay(3000);
    
    SDL_Quit();
    return 0;
}
