#!/usr/bin/Rscript

#source("/home/vicker/git_repos/crosslink/pag_poster/boxplot.R")

library(ggplot2)

# ====== comparison between crosslink and tmap and onemap: small map
data0 = read.table("stats/smallmap.csv",col.names=c("map","program","spearman","pearson","time"))
data0$treatment = "0pc"

data1 = read.table("stats/1pcerrormap.csv",col.names=c("map","program","spearman","pearson","time"))
data1$treatment = "1pc"

data2 = read.table("stats/2pcerrormap.csv",col.names=c("map","program","spearman","pearson","time"))
data2$treatment = "2pc"

data5 = read.table("stats/5pcerrormap.csv",col.names=c("map","program","spearman","pearson","time"))
data5$treatment = "5pc"

dat = rbind(data0,data1,data2,data5)

ggplot(dat, aes(x = program, y = pearson, fill = program)) + geom_boxplot() + facet_wrap(~ treatment)
ggsave(file="figs/small_pearson.png")

ggplot(dat, aes(x = program, y = time, fill = program)) + geom_boxplot() + facet_wrap(~ treatment)
ggsave(file="figs/small_time.png")

# ====== comparison between crosslink and tmap and onemap: medium map
dat3 = read.table("stats/mediummap.csv",col.names=c("map","program","spearman","pearson","time"))
#data0$treatment = "0pc"
ggplot(dat3, aes(x = program, y = pearson, fill = program)) + geom_boxplot()
ggsave(file="figs/medium_pearson.png")

ggplot(dat3, aes(x = program, y = time, fill = program)) + geom_boxplot()
ggsave(file="figs/medium_time.png")


# ====== test of crosslink alone
dat2 = read.table("stats/crosslinkonly.csv",col.names=c("error","markers","replicate","spearman","pearson","time"))
ggplot(dat2, aes(x = factor(error), y = pearson)) + geom_boxplot() + facet_wrap(~ markers,scales="free")
ggsave(file="figs/crosslink_pearson.png")

#ggplot(dat2, aes(x = markers, y = time)) + geom_point() + geom_smooth()
ggplot(dat2, aes(x = factor(markers), y = time)) + geom_boxplot()
ggsave(file="figs/crosslink_time.png")
