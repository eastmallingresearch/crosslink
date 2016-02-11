#ifndef _RJV_CROSSLINK_GRAPHICAL_H_
#define _RJV_CROSSLINK_GRAPHICAL_H_

#include <SDL2/SDL.h>
#include "crosslink_common.h"

//void show_info(struct lg*p,int offset);
uint32_t*generate_graphical(struct conf*c,struct lg*p,unsigned type);
//void which_markers(int mx,int my,SDL_Rect*img,SDL_Rect*win,int*imgx,int*imgy);
void calc_graphical(unsigned img_sizex,unsigned img_sizey,unsigned win_sizex,unsigned win_sizey,double img_centrex,double img_centrey,double img_widthx,double img_widthy,SDL_Rect*img,SDL_Rect*win);

#endif
