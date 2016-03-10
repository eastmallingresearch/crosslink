#ifndef _RJV_CROSSLINK_VIEWER_H_
#define _RJV_CROSSLINK_VIEWER_H_

#include <SDL2/SDL.h>
#include "crosslink_common.h"

#ifndef ALTCOLSCHEME
    //standard colour scheme: red=maternal, green=paternal, blue=repulsion phase
    #define setpixelrgb(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))
#else
    //alternative: switch red and blue, may be better for red-green colour blind users
    #define setpixelrgb(buff,x,y,w,b,g,r) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))
#endif

#define LOD_BRIGHTNESS_SCALE 0.04
#define LOD_BRIGHTNESS_MIN   20.0
#define DIST_BAND            10.0

unsigned find_marker(struct lg*p,char*name);
void show_info(struct lg*p,int offset);
void show_rf_lod(struct conf*c,struct lg*p,int xoff,int yoff);
uint32_t*generate_image(struct conf*c,struct lg*p,unsigned mode);
void which_markers(int mx,int my,SDL_Rect*img,SDL_Rect*win,int*imgx,int*imgy);
void calc_view(unsigned img_size,unsigned win_size,double img_centrex,double img_centrey,double img_width,SDL_Rect*img,SDL_Rect*win);

#endif
