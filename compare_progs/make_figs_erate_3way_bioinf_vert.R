#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#plot max memory usage, ordering accuracy, map expansion, CPU time

#run these first:
# ~/git_repos/crosslink/compare_progs/get_maxvmem_mdensity.sh
# ~/git_repos/crosslink/compare_progs/recalc_mapping_accuracy_mdensity.sh

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)
library(grid) # for R 3.2.3 for gpar

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/erate_simdata/figs")

lw = 0.2
lw2 = 0.1
ps = 1.5
ew = 0.05
sr = 0.2

erate_xlab="Error/Missing Rate (%)"

#modified from
#http://stackoverflow.com/questions/11610377/how-do-i-change-the-formatting-of-numbers-on-an-axis-with-ggplot
fancy_scientific <- function(l) {
     # turn in to character string in scientific notation
     l <- format(l, scientific = TRUE)
     # quote the part before the exponent to keep all the digits
     l <- gsub("^(.*)e", "'\\1'e", l)
     # turn the 'e+' into plotmath format
     l <- gsub("e", "%*%10^", l)
     # return this as an expression
     parse(text=l)
}
#assume all values are 1x10^something
fancy_scientific2 <- function(l) {
     # turn in to character string in scientific notation
     l <- format(l, scientific = TRUE)
     l <- gsub("^(.*)e", "e", l)
     l <- gsub("e", "10^", l)
     parse(text=l)
}

lq_func <- function(l, na.rm=na.rm)
{
    return(quantile(l, na.rm=na.rm)[[2]])
}

uq_func <- function(l, na.rm=na.rm)
{
    return(quantile(l, na.rm=na.rm)[[4]])
}

median_uq_lq_func <- function(df,response,grp1,grp2)
{
    df_median <- aggregate(df[[response]],by=list(df[[grp1]],df[[grp2]]),median,na.rm=T)
    colnames(df_median) <- c(grp1,grp2,"median")
    
    df_uq <- aggregate(df[[response]],by=list(df[[grp1]],df[[grp2]]),uq_func,na.rm=T)
    colnames(df_uq) <- c(grp1,grp2,"uq")

    df_lq <- aggregate(df[[response]],by=list(df[[grp1]],df[[grp2]]),lq_func,na.rm=T)
    colnames(df_lq) <- c(grp1,grp2,"lq")

    df <- merge(df_uq,df_lq)
    df <- merge(df,df_median)
    df$response = response
    
    return(df)
}

par(mar=c(0,0,0,0))

erate_brks <- c(1e-1,5e-1,1e0,3e0,6e0)

dat = read.table("erate_4way",col.names=c("algorithm","erate","t_user","t_sys","corr","missing","expansion"),stringsAsFactors=F)

dat$erate <- dat$erate * 100.0
dat$t_cpu = dat$t_user + dat$t_sys
dat$t_hrs = dat$t_cpu / 3600
dat$err = 1 - dat$corr

df_err <- median_uq_lq_func(dat,"err","algorithm","erate")
df_time <- median_uq_lq_func(dat,"t_hrs","algorithm","erate")
df_expan <- median_uq_lq_func(dat,"expansion","algorithm","erate")

df_err$algorithm <- as.factor(df_err$algorithm)
df_time$algorithm <- as.factor(df_time$algorithm)
df_expan$algorithm <- as.factor(df_expan$algorithm)

#===============ordering

p_order = ggplot(df_err, aes(x=erate, y=median, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    theme_bw() +
    scale_colour_grey(start=0.0,end=0.7) +
    scale_shape_manual(values=1:nlevels(df_err$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    ylab("Ordering Error") +
    #xlab(erate_xlab) +
    scale_y_log10(breaks=c(1e-3,1e-2,1e-1,1)) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "none" ,
          #panel.background = element_rect(colour="black"),
          #panel.background = element_rect(colour = "#dddddd"),
          #axis.line = element_line(colour = "black"),
          #axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          #panel.grid.major = element_line(colour = "#dddddd"),
          #panel.grid.minor = element_line(colour = "#dddddd"),
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial") #,
          #legend.key.size=unit(.1,"in")
          )


#============>time

p_time = ggplot(df_time, aes(x=erate, y=median, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    theme_bw() +
    scale_colour_grey(start=0.0,end=0.7) +
    scale_shape_manual(values=1:nlevels(df_time$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    ylab("CPU Time (hrs)") +
    #xlab(erate_xlab) +
    scale_y_log10(breaks=c(1e-5,1e-4,1e-3,1e-2,1e-1,1e0,1e1),labels=fancy_scientific2) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "none" ,
          #panel.background = element_rect(colour="black"),
          #panel.background = element_rect(colour = "#dddddd"),
          #axis.line = element_line(colour = "black"),
          #axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          #panel.grid.major = element_line(colour = "#dddddd"),
          #panel.grid.minor = element_line(colour = "#dddddd"),
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial") #,
          #legend.key.size=unit(.1,"in")
          )


#============>expansion

p_expan = ggplot(df_expan, aes(x=erate, y=median, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    theme_bw() +
    scale_shape_manual(values=1:nlevels(df_expan$algorithm)) +
    scale_colour_grey(start=0.0,end=0.7) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    ylab("Map Expansion") +
    xlab(erate_xlab) +
    scale_y_log10(breaks=c(1,2,10,20)) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "none" ,
          #panel.background = element_rect(colour="black"),
          #panel.background = element_rect(colour = "#dddddd"),
          #axis.line = element_line(colour = "black"),
          #axis.title.y = element_blank(),
          #axis.title.x = element_blank(),
          #panel.grid.major = element_line(colour = "#dddddd"),
          #panel.grid.minor = element_line(colour = "#dddddd"),
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial") #,
          #legend.key.size=unit(.1,"in")
          )

dpi=400
width=3.0
height=2.2
ptsize=10

ggsave("erate_ordering_400.png",plot=p_order,units="in",dpi=dpi,width=width,height=height)
ggsave("erate_time_400.png",plot=p_time,units="in",dpi=dpi,width=width,height=height)
ggsave("erate_expansion_400.png",plot=p_expan,units="in",dpi=dpi,width=width,height=height)
#ggsave("erate_legend_400.png",plot=plegend,units="in",dpi=dpi,width=width,height=height)
