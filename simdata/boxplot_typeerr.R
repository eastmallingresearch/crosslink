#!/usr/bin/Rscript

library(ggplot2)

dat = read.table("typeerr_stats/all_typeerr",
                 col.names=c("basename","density","mapsize","error_missing_rate","typeerr_rate","replicate","group_lod","matpat_lod","group_score","typeerr_score"))

#typeerr_score vs matpat_lod,group_lod
plt = ggplot(dat, aes(x = factor(matpat_lod), y = typeerr_score)) +
    geom_boxplot() +
    facet_wrap(~group_lod) +
    guides(fill=guide_legend(title="Type Correction Score versus GroupLod"))
ggsave(file="figs/typeerr_grouplod.png",plot=plt,dpi=600)

#typeerr_score vs matpat_lod,marker density
plt = ggplot(dat, aes(x = factor(matpat_lod), y = typeerr_score)) +
    geom_boxplot() +
    facet_wrap(~density) +
    guides(fill=guide_legend(title="Type Correction Score versus Marker Density"))
ggsave(file="figs/typeerr_density.png",plot=plt,dpi=600)

