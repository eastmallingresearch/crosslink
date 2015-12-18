#!/usr/bin/Rscript

#source("/home/vicker/git_repos/crosslink/pag_poster/boxplot.R")

library(ggplot2)

system("cat ./compare_progs/compare_*_stats > ./compare_progs/all_stats")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./compare_progs/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system"))
dat$score = 1.0 - dat$pearson

#pearson - map colinearity
ggplot(dat[dat$density == 10.0,], aes(x = program, y = 1-pearson, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    ylab("mapping error (logscale)")
ggsave(file="figs/compare_pearson_10.0.png")

#pearson - map colinearity
ggplot(dat[dat$density == 1.0,], aes(x = program, y = 1-pearson, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    ylab("mapping error (logscale)")
ggsave(file="figs/compare_pearson_1.0.png")

#pearson - map colinearity
ggplot(dat[dat$density == 0.1,], aes(x = program, y = 1-pearson, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    ylab("mapping error (logscale)")
ggsave(file="figs/compare_pearson_0.1.png")

#ggplot(dat, aes(x = interaction(program,density), y = spearman, fill = interaction(program,density))) +
#    geom_boxplot() +
#    facet_grid(markers ~ error) +
#    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
#ggsave(file="figs/compare_spearman.png")

#missing markers
ggplot(dat, aes(x = program, y = proportion, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_prop.png")

#run time
ggplot(dat, aes(x = program, y = user+system, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) + #,scales="free"
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("time (secs)")

ggsave(file="figs/compare_time.png")
