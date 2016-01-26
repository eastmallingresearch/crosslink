#!/usr/bin/Rscript

#
# compare RGxHA mapping results
#

library(ggplot2)

#system("~/git_repos/crosslink/pag_poster/060_collect_stats_rgxha.sh")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./stats/all_stats",col.names=c("Program","lg","centimorgans","nmarkers","time"))

give.n1 = function(dat)
{
  return(c(y = 0.0, label = length(dat)))
}

give.n2 = function(dat)
{
  return(c(y = 70000.0, label = length(dat)))
}

#change order of programs
#dat$program <- factor(dat$program, levels = dat$program[order(c(2,3,4,1,5))])

#dat$lgnumber = substr(dat$lg,1,1)
#dat$lgletter = substr(dat$lg,2,2)

#lgsize
ggplot(dat, aes(x = Program, y = centimorgans, fill = Program)) +
    geom_boxplot() +
    #facet_grid(lgnumber~lgletter) +
    #stat_summary(fun.data = give.n2, geom = "text", fun.y = 70000.0, size = 3) +
    #scale_y_log10() +
    scale_fill_manual(values = c("pink","green","cyan","purple")) +
    theme(axis.text.y = element_text(colour="black")) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    ylab("Linkage group size (centimorgans)")
ggsave(file="figs/rgxha_lgsize_aggregated.png",dpi=600)

#markers
#ggplot(dat, aes(x = program, y = nmarkers, fill = program)) +
#    geom_bar(stat="identity") +
#    facet_grid(lgnumber~lgletter) +
#    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
#ggsave(file="figs/rgxha_markers.png")

#run time
ggplot(dat, aes(x = Program, y = time/3600, fill = Program)) +
    geom_boxplot() +
    #facet_grid(lgnumber~lgletter) +
    #scale_y_log10() +
    scale_fill_manual(values = c("pink","green","cyan","purple")) +
    theme(axis.text.y = element_text(colour="black")) +
    scale_y_continuous(breaks = round(seq(0.0, max(dat$time/3600), by = 1.0),1)) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("Time (hours)")
ggsave(file="figs/rgxha_time_aggregate.png",dpi=600)

dat = read.table("./stats/all_compare",col.names=c("Comparison","spearman","pearson","proportion"))

ggplot(dat, aes(x = Comparison, y = pearson, fill = Comparison)) +
    geom_boxplot() +
    #facet_grid(lgnumber~lgletter) +
    #scale_y_log10() +
    #scale_fill_manual(values = c("grey","pink","green","cyan","purple")) +
    theme(axis.text.y = element_text(colour="black")) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("|Pearson correlation|")
ggsave(file="figs/rgxha_ordering_aggregate.png",dpi=600)
