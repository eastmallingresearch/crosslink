#!/usr/bin/Rscript

library(ggplot2)

#cat grouping001stats/grouping001* > grouping001stats/all_grouping001

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("grouping001stats/all_grouping001",
                 col.names=c("basename","density","mapsize","error_rate","missing_rate","replicate","group_lod","score"))

#score vs lod,density
plt = ggplot(dat, aes(x = factor(group_lod), y = score)) +
    geom_boxplot() +
    facet_wrap(~density) +
    guides(fill=guide_legend(title="Score versus marker density"))
ggsave(file="figs/grouping001_density.png",plot=plt,dpi=600)

#score vs lod,error rate
plt = ggplot(dat, aes(x = factor(group_lod), y = score)) +
    geom_boxplot() +
    facet_wrap(~error_rate) +
    guides(fill=guide_legend(title="Score versus error rate"))
ggsave(file="figs/grouping001_error.png",plot=plt,dpi=600)

#score vs lod,missing rate
plt = ggplot(dat, aes(x = factor(group_lod), y = score)) +
    geom_boxplot() +
    facet_wrap(~missing_rate) +
    guides(fill=guide_legend(title="Score versus missing rate"))
ggsave(file="figs/grouping001_missing.png",plot=plt,dpi=600)
