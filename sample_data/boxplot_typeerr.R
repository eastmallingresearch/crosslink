#!/usr/bin/Rscript

library(ggplot2)

#mkdir figs
#cat */score > all_scores

dat = read.table("all_scores",col.names=c("matpatlod","sample","typeerr","group","phase","knn","map"))

plt = ggplot(dat, aes(x = factor(matpatlod), y = typeerr)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="typeerr"))
ggsave(file="figs/typeerr.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(matpatlod), y = group)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="group"))
ggsave(file="figs/group.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(matpatlod), y = phase)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="phase"))
ggsave(file="figs/phase.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(matpatlod), y = knn)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="knn"))
ggsave(file="figs/knn.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(matpatlod), y = map)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="map"))
ggsave(file="figs/map.png",plot=plt,dpi=600)

