#!/usr/bin/Rscript

#
# compare RGxHA mapping results
#

library(ggplot2)

system("~/git_repos/crosslink/pag_poster/060_collect_stats_rgxha.sh")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./stats/all_stats",col.names=c("program","lg","centimorgans","nmarkers","time"))

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

dat$lgnumber = substr(dat$lg,1,1)
dat$lgletter = substr(dat$lg,2,2)

#lgsize
ggplot(dat, aes(x = program, y = centimorgans, fill = program)) +
    geom_bar(stat="identity") +
    facet_grid(lgnumber~lgletter) +
    #stat_summary(fun.data = give.n2, geom = "text", fun.y = 70000.0, size = 3) +
    #scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    #guides(fill=guide_legend(title="mapping program\n.markers per cM")) +
    #ylab("map expansion")
ggsave(file="figs/rgxha_lgsize.png")

#markers
ggplot(dat, aes(x = program, y = nmarkers, fill = program)) +
    geom_bar(stat="identity") +
    facet_grid(lgnumber~lgletter) +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank())
ggsave(file="figs/rgxha_markers.png")

#run time
ggplot(dat, aes(x = program, y = time, fill = program)) +
    geom_bar(stat="identity") +
    facet_grid(lgnumber~lgletter) +
    scale_y_log10() +
    theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
    ylab("time (secs, logscale)")
ggsave(file="figs/rgxha_time.png")
