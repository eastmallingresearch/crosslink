#!/usr/bin/Rscript

#Crosslink, Copyright (C) 2016  NIAB EMR

#compare performance versus minlod used for grouping and whether
#approx ordering prioritises nonhk edges or not

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)

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
    ylab("1 - Mapping Score") +
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

#log time versus algorithm
#p3 = ggplot(dat, aes(x = factor(algorithm), y = t_real)) +
#    geom_boxplot() +
#    scale_y_log10() +   
#    #scale_y_log10(breaks=c(1e-1,1e+1,1e+3),labels=c("0.1","10","1000")) +
#    ylab("Real Time (secs)") +
#    xlab("Algorithm") +
#    theme

plots = matrix(list(ggplotGrob(p1),ggplotGrob(p2)),nrow=1,byrow=TRUE)
w=unit(c(1,1),"null")
h=unit(c(1),"null")
z=matrix(c(1,2),nrow=1)
gp = gpar(lwd = 3, fontsize = 18)
gtab = gtable_matrix("X",grobs=plots,widths=w,heights=h,z=z)
gtab = gtable_add_grob(gtab, textGrob("A", x=0.01, y=0.98, hjust=0,vjust=1,gp=gp), t=1, l=1, b=1,r=2,clip="off",z=100,name="A")
gtab = gtable_add_grob(gtab, textGrob("B", x=0.51, y=0.98, hjust=0,vjust=1,gp=gp), t=1, l=1, b=1, r=2, clip="off",z=101,name="B")

res=300
width=7.5
height=3.25
tiff("6.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white")
grid.draw(gtab)
dev.off()


ggsave("realtime.png")
