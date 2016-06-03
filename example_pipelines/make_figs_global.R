#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#compare LOD-distance plot from recomb versus global optimisation

library(ggplot2)
library(gridExtra)
library(gtable)
library(png)

setwd("~/crosslink/ploscompbiol_data/rgxha")

theme = theme(
  #panel.background = element_rect(fill="white"),
  #axis.ticks = element_line(colour=NA),
  #panel.grid = element_line(colour="grey"),
  axis.text.y = element_text(colour="black"),
  axis.text.x = element_text(colour="black"),
  text = element_text(size=8, family="Arial"),
  title = element_text(size=12, family="Arial")
)

i1 = readPNG("017.000.mat.recomb.png")
i2 = readPNG("017.000.mat.global.png")
i3 = readPNG("017.000.pat.recomb.png")
i4 = readPNG("017.000.pat.global.png")

p1 = rasterGrob(i1, interpolate=FALSE) 
p2 = rasterGrob(i2, interpolate=FALSE) 
p3 = rasterGrob(i3, interpolate=FALSE) 
p4 = rasterGrob(i4, interpolate=FALSE) 

plots = matrix(list(p1,p2,p3,p4),nrow=2,byrow=TRUE)
w=unit(c(1,1),"null")
h=unit(c(1,1),"null")
z=matrix(c(1,2,3,4),nrow=2)
gp = gpar(lwd = 3, fontsize = 18, col="white")
gtab = gtable_matrix("X",grobs=plots,widths=w,heights=h,z=z)
gtab = gtable_add_grob(gtab, textGrob("A", x=0.01, y=0.95, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2,r=2,clip="off",z=100,name="A")
gtab = gtable_add_grob(gtab, textGrob("B", x=0.51, y=0.95, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=101,name="B")
gtab = gtable_add_grob(gtab, textGrob("C", x=0.01, y=0.45, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=102,name="C")
gtab = gtable_add_grob(gtab, textGrob("D", x=0.51, y=0.45, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=103,name="D")

res=300
width=7.5
height=7.5
ptsize=10
tiff("8.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()
