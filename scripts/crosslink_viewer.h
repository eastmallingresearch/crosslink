#ifndef _RJV_CROSSLINK_VIEWER_H_
#define _RJV_CROSSLINK_VIEWER_H_

#include <SDL2/SDL.h>
#include "crosslink_common.h"

#define setpixelrgb(buff,x,y,w,r,g,b) ((buff)[(y)*(w)+(x)] = ((r)<<16)+((g)<<8)+(b))

void show_info(struct lg*p,int offset);
void show_rf_lod(struct conf*c,struct lg*p,int xoff,int yoff);
uint32_t*generate_image(struct conf*c,struct lg*p,double minlod);
void which_markers(int mx,int my,SDL_Rect*img,SDL_Rect*win,int*imgx,int*imgy);
void calc_view(unsigned img_size,unsigned win_size,double img_centrex,double img_centrey,double img_width,SDL_Rect*img,SDL_Rect*win);

#endif
