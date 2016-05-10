#!/usr/bin/Rscript
#compare mapping performance between programs / modes of operation

library(ggplot2)

setwd("/home/vicker/crosslink/ploscompbiol_data/compare_simdata")

system("cat */score > all_scores")

dat = read.table("all_scores",col.names=c("algorithm","sample","t_real","t_user","t_sys","accuracy"))
dat$t_cpu = dat$t_user + dat$t_sys
dat$err = 1.0 - dat$accuracy

#mapping score versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = accuracy)) +
    geom_boxplot() +
    ylab("mapping score") +
    xlab("algorithm")
ggsave(file="figs/accuracy_vs_algorithm.png",plot=plt,dpi=600)

#log error versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = err)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("error") +
    xlab("algorithm")
ggsave(file="figs/logerr_vs_algorithm.png",plot=plt,dpi=600)

#cpu time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_cpu)) +
    geom_boxplot() +
    ylab("cpu time (secs)") +
    xlab("algorithm")
ggsave(file="figs/cputime_vs_algorithm.png",plot=plt,dpi=600)

#log time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_cpu)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("cpu time (secs)") +
    xlab("algorithm")
ggsave(file="figs/logcputime_vs_algorithm.png",plot=plt,dpi=600)

#log real time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_real)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("real time (secs)") +
    xlab("algorithm")
ggsave(file="figs/logrealtime_vs_algorithm.png",plot=plt,dpi=600)
