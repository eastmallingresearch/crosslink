#!/usr/bin/Rscript

library(ggplot2)

#mkdir figs
#cat */score > all_scores
#cat all_scores | awk '{printf "%d %f %f %s %f %d_%f_%f\n",$1,$2,$3,$4,$5,$1,$2,$3}' > all_scores_extra

dat = read.table("all_scores_extra",col.names=c("min_count","min_lod","max_lod","sample","score","treatment"))

plt = ggplot(dat, aes(x = factor(treatment), y = score)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="score versus treatment"))
ggsave(file="figs/score_vs_treatment.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(min_count), y = score)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="score versus mincount"))
ggsave(file="figs/score_vs_mincount.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(min_lod), y = score)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="score versus minlod"))
ggsave(file="figs/score_vs_minlod.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(max_lod), y = score)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="score versus maxlod"))
ggsave(file="figs/score_vs_maxlod.png",plot=plt,dpi=600)

levels(factor(dat$treatment))
