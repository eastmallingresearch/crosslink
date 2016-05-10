#!/usr/bin/Rscript
#compare performance versus minlod used for grouping and whether
#approx ordering prioritises nonhk edges or not

library(ggplot2)
library(scales)
library(gridExtra)

setwd("~/crosslink/ploscompbiol_data/compare_simdata/figs")

theme = theme(
  #panel.background = element_rect(fill="white"),
  #axis.ticks = element_line(colour=NA),
  #panel.grid = element_line(colour="grey"),
  axis.text.y = element_text(colour="black"),
  axis.text.x = element_text(colour="black",angle=45,hjust=1),
  text = element_text(size=8, family="Arial"),
  title = element_text(size=12, family="Arial")
)

system("cat ../*/score > compare_data")

dat = read.table("compare_data",col.names=c("algorithm","sample","t_real","t_user","t_sys","accuracy"))
dat$t_cpu = dat$t_user + dat$t_sys

#log error versus algorithm
p1 = ggplot(dat, aes(x = factor(algorithm), y = 1 - accuracy)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("1 - Mapping Accuracy") +
    xlab("Algorithm") +
    theme

#log time versus algorithm
p2 = ggplot(dat, aes(x = factor(algorithm), y = t_cpu)) +
    geom_boxplot() +
    #scale_y_log10() +   
    scale_y_log10(breaks=c(1e-1,1e+1,1e+3),labels=c("0.1","10","1000")) +
    ylab("CPU Time (secs)") +
    xlab("Algorithm") +
    theme

res=300
width=7.5
height=3.25
tiff("5.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white")
grid.arrange(p1,p2,ncol=2)
dev.off()
