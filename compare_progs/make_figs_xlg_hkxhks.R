#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#plot number of same-type linked verus other-type linked markers
#to demonstrate that some markers appear to be incorrectly typed

#~/crosslink/ploscompbiol_data/rgxha/show_crosslg

#uses build_rgxha.sh, stopped after detection of crosslg markers
#activated printf in detect function of crosslink_ga.c

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)
library(grid) # for R 3.2.3 for gpar

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/rgxha/show_crosslg")

lw = 0.3
ps = 0.5
ew = 0.05

dat1 = read.table("xlg_not2",col.names=c("dummy","m1","m2","LOD1","LOD2"))
dat1$class = "okay"
dat2 = read.table("xlg_bad2",col.names=c("dummy","m1","m2","LOD1","LOD2"))
dat2$class = "detected"
dat3 = read.table("xlg_bad3",col.names=c("dummy","m1","m2","LOD1","LOD2"))
dat3$class = "missed"


dat = rbind(dat1,dat2,dat3)
dat$class = factor(dat$class)

p = ggplot(dat, aes(x=LOD1, y=LOD2,colour=class,shape=class)) +
    xlab("Weakest Linkage LOD") +
    ylab("Strongest Linkage LOD") +
    geom_point(size=ps) +
    theme(#axis.title.x=element_blank(),
          #axis.text.x=element_blank(),
          #axis.ticks.x=element_blank(),
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial"),
          legend.key.size=unit(.1,"in")
        )

res=300
width=3.75
height=2.75
ggsave("xlg.tiff",width=width,height=height,units="in",dpi=res,compression="lzw")
