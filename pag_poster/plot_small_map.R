#!/usr/bin/Rscript
library(ggplot2)



data1 = read.table("stats/smallmap.csv",col.names=c("map","program","spearman","pearson","time"))
data1$treatment = "small"

data2 = read.table("stats/mediummap.csv",col.names=c("map","program","spearman","pearson","time"))
data2$treatment = "medium"

data3 = read.table("stats/1pcerrormap.csv",col.names=c("map","program","spearman","pearson","time"))
data3$treatment = "1pc"

data4 = read.table("stats/2pcerrormap.csv",col.names=c("map","program","spearman","pearson","time"))
data4$treatment = "2pc"

ggplot(data)+geom_point(aes(x=pearson,y=time))+facet_wrap(~program)
