#!/usr/bin/Rscript
#compare performance versus minlod used for grouping and whether
#approx ordering prioritises nonhk edges or not

library(ggplot2)

setwd("~/crosslink/ploscompbiol_data/simdata/test_group")
system("cat */score > all_scores")
dat = read.table("all_scores",col.names=c("minlod","nonhk","sample","typeerr","group","phase","knn","map"))
dat$logmap = log10(1.0 - dat$map)

setwd("~/crosslink/ploscompbiol_data/figs")

#minlod + nonhk versus mapping score
plt = ggplot(dat, aes(x = factor(minlod), y = logmap)) +
    geom_boxplot() +
    facet_wrap(~nonhk) +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    ylab("log10(1 - mapping score)") +
    xlab("grouping LOD")
ggsave(file="figs/minlod_vs_mappingscore.png",plot=plt,dpi=600)

#minlod versus grouping score
plt = ggplot(dat, aes(x = factor(minlod), y = group)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    ylab("grouping score") +
    xlab("grouping LOD")
ggsave(file="figs/minlod_vs_groupingscore.png",plot=plt,dpi=600)

#minlod versus phasing accuracy
plt = ggplot(dat, aes(x = factor(minlod), y = phase)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    ylab("phasing score") +
    xlab("grouping LOD")
ggsave(file="figs/minlod_vs_phasingscore.png",plot=plt,dpi=600)

#minlod versus type correction score
plt = ggplot(dat, aes(x = factor(minlod), y = typeerr)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    ylab("type correction score") +
    xlab("grouping LOD")
ggsave(file="figs/minlod_vs_typecorrection.png",plot=plt,dpi=600)


plt = ggplot(dat, aes(x = factor(minlod), y = knn)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="knn"))
ggsave(file="figs/knn.png",plot=plt,dpi=600)


