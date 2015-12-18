#!/usr/bin/Rscript

library(ggplot2)

system("cat ./compare_crosslink/compare_*_stats > ./compare_crosslink/all_stats")

# ====== comparison crosslink performance on different maps
dat = read.table("./compare_crosslink/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system"))
dat$score = 1.0 - dat$pearson

for (den in c(0.1,1,10))
{
    #pearson - map colinearity
    ggplot(dat[dat$density == den,], aes(x = program, y = 1-pearson, fill = program)) +
        geom_boxplot() +
        facet_grid(markers ~ error) +
        #scale_y_log10() +
        theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
        #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
        ylab("mapping error")
    ggsave(file=sprintf("figs/crosslink_pearson_%.1f.png",den))

    #map expansion
    #ggplot(dat[dat$density == den,], aes(x = program, y = expansion, fill = program)) +
    #    geom_boxplot() +
    #    facet_grid(markers ~ error) +
    #    #scale_y_log10() +
    #    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    #    ylab("map expansion")
    #ggsave(file="figs/crosslink_expansion_%.1f.png",den))
}

#proportion
ggplot(dat, aes(x = program, y = proportion, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/crosslink_prop.png")

#time
ggplot(dat[dat$program == 'crosslink',], aes(x = factor(markers), y = user+system)) +
    geom_boxplot() +
    #facet_grid(markers) + #,scales="free"
    scale_y_log10() +
    #theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("time (secs)")
ggsave(file="figs/crosslink_time.png")
