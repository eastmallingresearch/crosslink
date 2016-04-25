//
// test SDL2
//

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <SDL2/SDL.h>
//#include <inttypes.h>

#define setpixel(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))

int main(int argc, char**argv)
{
    SDL_Window* win = NULL;
    SDL_Renderer* ren = NULL;
    SDL_Texture* tex = NULL;
    SDL_Event eve;
    char*smoothing="nearest"; //nearest or linear
    
    unsigned width = 3000;
    unsigned height = 4000;
    unsigned i,r,g,b,x,y;
    int sizew,sizeh;          //actual window size
    
    uint32_t*buff=NULL;
    
    srand(time(NULL));
    
    assert(buff = calloc(width*height,sizeof(uint32_t)));
    
    for(x=0; x<width; x++)
    {
        for(y=0; y<height; y++)
        {
            r = x % 256;
            g = y % 256;     //i / 256;
            b = 0;           //rand() % 256;
            //buff[y*width+x] = (r<<16)+(g<<8)+b;
            setpixel(buff,x,y,width,r,g,b);
        }
    }
    
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        printf("SDL_Init Error: %s\n",SDL_GetError());
        return 1;
    }
    
    assert(win = SDL_CreateWindow("Hello World!",
                                  SDL_WINDOWPOS_UNDEFINED,SDL_WINDOWPOS_UNDEFINED,
                                  10, 10,SDL_WINDOW_SHOWN|SDL_WINDOW_MAXIMIZED|SDL_WINDOW_RESIZABLE));
                                  //SDL_WINDOW_FULLSCREEN_DESKTOP));
                                  
    assert(ren = SDL_CreateRenderer(win, -1, 0));

    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, smoothing); //"linear" or "nearest"
    //SDL_RenderSetLogicalSize(ren, width, height);-

    assert(tex = SDL_CreateTexture(ren,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING, width, height));

    SDL_UpdateTexture(tex, NULL, buff, width * sizeof (uint32_t));

    SDL_RenderClear(ren);
    SDL_RenderCopy(ren, tex, NULL, NULL);
    SDL_RenderPresent(ren);
    
    SDL_Rect src;
    SDL_Rect dst;
    
    double vx = (double)width / 2.0;
    double vy = (double)height / 2.0;
    double scl = 0.5;

    src.x = 0;
    src.y = 0;
    src.w = width;
    src.h = height;
    
    SDL_GetWindowSize(win,&sizew,&sizeh);
    printf("window size: %d,%d\n",sizew,sizeh);
    SDL_GetWindowMaximumSize(win,&sizew,&sizeh);
    printf("max window size: %d,%d\n",sizew,sizeh);

    while(1)
    {
        SDL_WaitEvent(&eve);
        
        if(eve.type == SDL_QUIT) break;
        
        if(eve.type == SDL_KEYDOWN)
        {
            //quit
            if(eve.key.keysym.sym == SDLK_q) break;
            if(eve.key.keysym.sym == SDLK_ESCAPE) break;
            
            //scaling method
            if(eve.key.keysym.sym == SDLK_n) SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY,"nearest");
            if(eve.key.keysym.sym == SDLK_l) SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY,"linear");
            
            //reset view
            if(eve.key.keysym.sym == SDLK_RETURN || eve.key.keysym.sym == SDLK_RETURN2)
            {
                vx = (double)width / 2.0;
                vy = (double)height / 2.0;
                scl = 0.5;
            }
            
            //zoom in / out
            if(eve.key.keysym.sym == SDLK_PLUS ||  eve.key.keysym.sym == SDLK_KP_PLUS)
            {
                scl /= 1.01;
            }
            if(eve.key.keysym.sym == SDLK_MINUS ||  eve.key.keysym.sym == SDLK_KP_MINUS)
            {
                scl *= 1.01;
            }
        }
        
        if(eve.type == SDL_MOUSEBUTTONDOWN)
        {
            printf("(%d,%d)\n",eve.button.x,eve.button.y);
        }

        dst.x = vx - scl * (double)width;
        dst.y = vy - scl * (double)height;
        dst.w = 2.0 * scl * (double)width;
        dst.h = 2.0 * scl * (double)height;
        
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, &src, &dst);
        SDL_RenderPresent(ren);
    }
    
    SDL_Quit();
    return 0;
}
