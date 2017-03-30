#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#plot number of same-type linked verus other-type linked markers
#to demonstrate that some markers appear to be incorrectly typed

#~/crosslink/ploscompbiol_data/rgxha/show_type_error

#crosslink_rflod --inp=./all.loc --out=all.rflod --min_lod=3.0 --matpat_lod=3.0
#cat ./fixtypes.log | grep 'type corr' | cut -d' ' -f4 > fixed_ids
#~/git_repos/crosslink/compare_progs/count_matpat_linkages.py all.loc all.rflod > counts
#grep -f fixed_ids counts > fixed_counts
#grep -v -f fixed_ids counts > nonfixed_counts

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)
library(grid) # for R 3.2.3 for gpar

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/rgxha/show_type_error")

lw = 0.3
ps = 0.5
ew = 0.05

dat1 = read.table("fixed_counts2",col.names=c("clusters","marker","type","same","other"))
dat1$class = "corrected"
dat2 = read.table("nonfixed_counts2",col.names=c("clusters","marker","type","same","other"))
dat2$class = "non-corrected"


dat = rbind(dat2,dat1)
dat$class = factor(dat$class)

#===============ordering
p = ggplot(dat, aes(x=same, y=other,colour=clusters,shape=class)) +
    xlab("Linked Same-Parent Markers") +
    ylab("Linked Other-Parent Markers") +
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
ggsave("count_fixed.tiff",width=width,height=height,units="in",dpi=res,compression="lzw")
