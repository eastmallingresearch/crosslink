#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#varying knn parameter

library(ggplot2)

system("cat */score > all_scores")

dat = read.table("all_scores",col.names=c("k","sample","typeerr","group","phase","knn","map"))

#missing data imputation accuracy versus knn
plt = ggplot(dat, aes(x = factor(k), y = knn)) +
    geom_boxplot() +
    ylab("knn imputation score") +
    xlab("k")
ggsave(file="figs/knn_vs_knnscore.png",plot=plt,dpi=600)

#approx ordering score versus knn
plt = ggplot(dat, aes(x = factor(k), y = map)) +
    geom_boxplot() +
    ylab("approx ordering score") +
    xlab("k")
ggsave(file="figs/knn_vs_approxordering.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(k), y = typeerr)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="typeerr"))
ggsave(file="figs/typeerr.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(k), y = group)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="group"))
ggsave(file="figs/group.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(k), y = phase)) +
    geom_boxplot() +
    stat_summary(fun.y=mean, geom="line", aes(group=1)) +
    guides(fill=guide_legend(title="phase"))
ggsave(file="figs/phase.png",plot=plt,dpi=600)



