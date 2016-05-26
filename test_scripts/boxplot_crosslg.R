#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
library(ggplot2)

#cat */score > all_scores

dat = read.table("all_scores",col.names=c("min_count","min_lod","max_lod","treatment","sample","score"))

r1<-with(dat, tapply(score, treatment, mean))
r1

plt = ggplot(dat, aes(x = factor(treatment), y = score)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1))
    guides(fill=guide_legend(title="treatment"))
ggsave(file="figs/treatment.png",plot=plt,dpi=600)
#    stat_summary(fun.y=mean, geom="line", aes(group=1))

plt = ggplot(dat, aes(x = min_count, y = score)) +
    geom_point() +
    guides(fill=guide_legend(title="mincount"))
ggsave(file="figs/mincount.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = min_lod, y = score)) +
    geom_point() +
    guides(fill=guide_legend(title="minlod"))
ggsave(file="figs/minlod.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = max_lod, y = score)) +
    geom_point() +
    guides(fill=guide_legend(title="maxlod"))
ggsave(file="figs/maxlod.png",plot=plt,dpi=600)

levels(factor(dat$treatment))
