#!/usr/bin/Rscript

#source("/home/vicker/git_repos/crosslink/pag_poster/boxplot.R")

library(ggplot2)

system("cat ./compare_progs/compare_*_stats > ./compare_progs/all_stats")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./compare_progs/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system"))
dat$score = 1.0 - dat$pearson

ggplot(dat, aes(x = program, y = 1-pearson, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_pearson.png")

ggplot(dat, aes(x = program, y = spearman, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_spearman.png")

ggplot(dat, aes(x = program, y = proportion, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_prop.png")

ggplot(dat, aes(x = program, y = user+system, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) + #,scales="free"
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_time.png")
