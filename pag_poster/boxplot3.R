#!/usr/bin/Rscript

library(ggplot2)

system("cat ./compare_crosslink/compare_*_stats > ./compare_crosslink/all_stats")

# ====== comparison crosslink performance on different maps
dat = read.table("./compare_crosslink/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system"))
dat$score = 1.0 - dat$pearson

ggplot(dat, aes(x = factor(density), y = 1-pearson, fill = factor(density))) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    #scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    ylab("mapping error")
    #ylab("mapping error (logscale)")
ggsave(file="figs/crosslink_pearson.png")

#ggplot(dat, aes(x = interaction(program,density), y = spearman, fill = interaction(program,density))) +
#    geom_boxplot() +
#    facet_grid(markers ~ error) +
#    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
#ggsave(file="figs/crosslink_spearman.png")

ggplot(dat, aes(x = program, y = proportion, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/crosslink_prop.png")

ggplot(dat, aes(x = factor(markers), y = user+system)) +
    geom_boxplot() +
    #facet_grid(markers ~ error) + #,scales="free"
    scale_y_log10() +
    #theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("time (secs)")
ggsave(file="figs/crosslink_time.png")
