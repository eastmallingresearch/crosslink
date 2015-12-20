#!/usr/bin/Rscript

#source("/home/vicker/git_repos/crosslink/pag_poster/boxplot.R")

library(ggplot2)

system("cat ./compare_progs/compare_*_stats | awk 'NF==12' > ./compare_progs/all_stats")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./compare_progs/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system","expansion"))
dat$score = 1.0 - dat$pearson

give.n1 = function(dat)
{
  return(c(y = 0.0, label = length(dat))) 
}

give.n2 = function(dat)
{
  return(c(y = 70000.0, label = length(dat))) 
}

#change order of programs
dat$program <- factor(dat$program, levels = dat$program[order(c(2,3,4,1,5))])

for (den in c(0.1,1,10))
{
    #pearson - map colinearity
    ggplot(dat[dat$density == den,], aes(x = program, y = pearson, fill = program)) +
        geom_boxplot() +
        stat_summary(fun.data = give.n1, geom = "text", fun.y = 0.0, size = 3) +
        facet_grid(markers ~ error) +
        #scale_y_log10() +
        theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
        #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
        ylab("|Pearson correlation|")
    ggsave(file=sprintf("figs/compare_pearson_%.1f.png",den))

    #map expansion
    ggplot(dat[dat$density == den,], aes(x = program, y = expansion, fill = program)) +
        geom_boxplot() +
        facet_grid(markers ~ error) +
        scale_y_log10() +
        theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
        #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
        ylab("map expansion")
    ggsave(file=sprintf("figs/compare_expansion_%.1f.png",den))
}

#missing markers
ggplot(dat, aes(x = program, y = proportion, fill = program)) +
    geom_boxplot() +
    facet_grid(markers ~ error) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/compare_prop.png")

#run time
ggplot(dat[dat$program != "optimal",], aes(x = program, y = user+system, fill = program)) +
    geom_boxplot() +
    #stat_summary(fun.data = give.n2, geom = "text", fun.y = 70000.0, size = 3) +
    facet_grid(markers ~ error) + #,scales="free"
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("time (secs)")

ggsave(file="figs/compare_time.png")
