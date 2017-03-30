#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

#plot max memory usage, ordering accuracy, map expansion, CPU time

#run these first:
# ~/git_repos/crosslink/compare_progs/get_maxvmem_mdensity.sh
# ~/git_repos/crosslink/compare_progs/recalc_mapping_accuracy_mdensity.sh
# ~/git_repos/crosslink/compare_progs/get_maxvmem_erate.sh
# ~/git_repos/crosslink/compare_progs/recalc_mapping_accuracy_erate.sh
# afterwards run:
# ~/git_repos/crosslink/compare_progs/

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)
library(grid) # for R 3.2.3 for gpar


lw = 0.2
lw2 = 0.1
ps = 2.0
ew = 0.05
sr = 0.2


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

fancy_scientific3 <- function(l) {
     parse(text=sprintf("10^%d",as.integer(log10(l))))
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

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/erate_simdata/figs")
#variable = erate
dat = read.table("erate_4way",col.names=c("algorithm","variable","t_user","t_sys","corr","missing","expansion"))
dat = subset(dat,algorithm != "cl_redun" & algorithm != "cl_refine" & algorithm != "cl_global")

dat$variable <- dat$variable * 100.0
dat$t_cpu = dat$t_user + dat$t_sys
dat$t_hrs = dat$t_cpu / 3600
dat$err = 1 - dat$corr

df_err <- median_uq_lq_func(dat,"err","algorithm","variable")
df_time <- median_uq_lq_func(dat,"t_hrs","algorithm","variable")
df_expan <- median_uq_lq_func(dat,"expansion","algorithm","variable")

df <- rbind(df_err,df_time,df_expan)
df$treatment = "erate"

erate_brks <- c(1e-1,5e-1,1e0,3e0,6e0)

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/mdensity_simdata/figs")
#variable = mdensity
dat = read.table("mdensity_4way",col.names=c("algorithm","variable","t_user","t_sys","corr","missing","expansion"))
dat = subset(dat,variable != 1000 & algorithm != "cl_redun" & algorithm != "cl_refine" & algorithm != "cl_global")

dat$t_cpu = dat$t_user + dat$t_sys
dat$t_hrs = dat$t_cpu / 3600
dat$err = 1 - dat$corr
dat$variable = dat$variable * 100 #convert density to number of markers

df_err <- median_uq_lq_func(dat,"err","algorithm","variable")
df_time <- median_uq_lq_func(dat,"t_hrs","algorithm","variable")
df_expan <- median_uq_lq_func(dat,"expansion","algorithm","variable")

df2 <- rbind(df_err,df_time,df_expan)
df2$treatment = "mdensity"

df <- rbind(df,df2)

df$alg = match(df$algorithm,levels(df$algorithm))
df$shape = as.factor(df$alg%%5)
df$colour = as.factor(df$alg%%3)
df$line = as.factor(df$alg%%2)

#==== plot

pp <- ggplot(df, aes(x=variable, y=median, shape=algorithm, colour=algorithm)) + 
    theme_bw() +
    #scale_colour_grey(start=0.0,end=0.7) +
    scale_shape_manual(values=c(15,16,22,1,2,5,6)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), linetype="solid", width=ew, size=lw2) +
    geom_line(size=lw,linetype="dashed") +
    geom_point(size=ps,stroke=sr) +
    facet_grid(response~treatment,scales="free") +
    #ylab("") +
    #xlab("Error/Missing Rate (%)") +
    #scale_y_log10(breaks=c(1e-3,1e-2,1e-1,1)) +
    scale_y_log10(breaks=c(0.00001,0.0001,0.001,0.01,0.1,1,10,100,1000),labels=fancy_scientific3) +
    scale_x_log10(breaks=c(0.1,0.5,1.0,3.0,6.0,100,500,1000,5000,10000,20000)) +           #breaks=erate_brks) +
    theme(legend.position = "right",
          legend.text = element_text(size=7, family="Arial"),
          legend.key.size=unit(.2,"in"),
          legend.key=element_blank(),
          #panel.background = element_rect(colour="black"),
          #panel.background = element_rect(colour = "#dddddd"),
          #axis.line = element_line(colour = "black"),
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          strip.background = element_blank(),
          strip.text.y = element_blank(),
          strip.text.x = element_blank(),
          panel.margin = unit(0, "lines"),
          #panel.grid.major = element_line(colour = "#dddddd"),
          #panel.grid.minor = element_line(colour = "#dddddd"),
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial") #,
          #legend.key.size=unit(.1,"in")
          )

dpi=400
width=6.0
height=6.0
ptsize=10

ggsave("facet_400_plot.png",plot=pp,units="in",dpi=dpi,width=width,height=height)
