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
ps = 0.9
ew = 0.05
sr = 0.2

erate_xlab="Error/Missing Rate (%)"

#http://www.cookbook-r.com/Manipulating_data/Summarizing_data/
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
    library(plyr)

    # New version of length which can handle NA's: if na.rm==T, don't count them
    length2 <- function (x, na.rm=FALSE) {
        if (na.rm) sum(!is.na(x))
        else       length(x)
    }

    # This does the summary. For each group's data frame, return a vector with
    # N, mean, and sd
    datac <- ddply(data, groupvars, .drop=.drop,
      .fun = function(xx, col) {
        c(N    = length2(xx[[col]], na.rm=na.rm),
          mean = mean   (xx[[col]], na.rm=na.rm),
          median = median   (xx[[col]], na.rm=na.rm),
          lq = quantile(xx[[col]], na.rm=na.rm)[[2]],
          uq = quantile(xx[[col]], na.rm=na.rm)[[4]],
          sd   = sd     (xx[[col]], na.rm=na.rm)
        )
      },
      measurevar
    )

    # Rename the "mean" column    
    #datac <- rename(datac, c("mean" = measurevar))
    datac <- rename(datac, c("median" = measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval: 
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}

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

#plot approx mem usage
dat2 = read.table("maxvmem_stats_mod",col.names=c("algorithm","erate","maxvmem"))

datsum2 <- summarySE(dat2, measurevar="maxvmem", groupvars=c("algorithm","erate"))

#==============>memory
p1 = ggplot(datsum2, aes(x=erate, y=maxvmem, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum2$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw) +
    geom_line(size=lw) +
    geom_point(size=ps) +
    ylab("Approx. Max. Memory") +
    xlab(erate_xlab) +
    scale_y_log10() +
    scale_x_log10(breaks=c(1e-3,1e-2,6e-2))
# + theme


dat = read.table("erate_4way",col.names=c("algorithm","erate","t_user","t_sys","corr","missing","expansion"))

dat$erate <- dat$erate * 100.0
erate_brks <- c(1e-1,5e-1,1e0,3e0,6e0)

dat_extra <- rbind(dat,c(NA,1,1,1,0.99,0,1.0))

dat_extra$algorithm <- as.character(dat_extra$algorithm)

dat_extra[nrow(dat_extra),1] <- "cl_redun"

dat_extra$algorithm <- as.factor(dat_extra$algorithm)


dat$t_cpu = dat$t_user + dat$t_sys
dat$t_hrs = dat$t_cpu / 3600
dat$err = 1 - dat$corr

dat_extra$t_cpu = dat_extra$t_user + dat_extra$t_sys
dat_extra$t_hrs = dat_extra$t_cpu / 3600
dat_extra$err = 1 - dat_extra$corr

#===============ordering
datsum <- summarySE(dat, measurevar="err", groupvars=c("algorithm","erate"))
datsum_extra <- summarySE(dat_extra, measurevar="err", groupvars=c("algorithm","erate"))

p2 = ggplot(datsum, aes(x=erate, y=err, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum_extra$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    geom_blank(data=datsum_extra) +
    ylab("Ordering Error") +
    xlab(erate_xlab) +
    scale_y_log10(breaks=c(1e-3,1e-2,1e-1,1)) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "none",
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial"),
          legend.key.size=unit(.1,"in"))


#============>time
datsum <- summarySE(dat, measurevar="t_hrs", groupvars=c("algorithm","erate"))
datsum_extra <- summarySE(dat_extra, measurevar="t_hrs", groupvars=c("algorithm","erate"))

p3 = ggplot(datsum, aes(x=erate, y=t_hrs, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum_extra$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    geom_blank(data=datsum_extra) +
    ylab("CPU Time (hrs)") +
    xlab(erate_xlab) +
    scale_y_log10(breaks=c(1e-5,1e-4,1e-3,1e-2,1e-1,1e0,1e1),labels=fancy_scientific2) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "none",
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial"),
          legend.key.size=unit(.1,"in"))


#============>expansion
datsum <- summarySE(dat, measurevar="expansion", groupvars=c("algorithm","erate"))
datsum_extra <- summarySE(dat_extra, measurevar="expansion", groupvars=c("algorithm","erate"))

p4 = ggplot(datsum, aes(x=erate, y=expansion, colour=algorithm, shape=algorithm, linetype=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum_extra$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw2, linetype='solid') +
    geom_line(size=lw) +
    geom_point(size=ps,stroke=sr) +
    geom_blank(data=datsum_extra) +
    ylab("Map Expansion") +
    xlab(erate_xlab) +
    scale_y_log10(breaks=c(1,2,10,20)) +
    scale_x_log10(breaks=erate_brks) +
    theme(legend.position = "right",
          text = element_text(size=8, family="Arial"),
          title = element_text(size=8, family="Arial"),
          legend.key.size=unit(.1,"in"))


plots = matrix(list(ggplotGrob(p2),ggplotGrob(p3),ggplotGrob(p4)),nrow=1,byrow=TRUE)
w=unit(c(0.72,0.72,1),"null")
h=unit(c(1),"null")
z=matrix(c(1,2,3),nrow=1)
gp = gpar(lwd = 3, fontsize = 10)
gtab = gtable_matrix("X", grobs=plots, widths=w, heights=h, z=z)
gtab = gtable_add_grob(gtab, textGrob("A", x=0.01, y=0.99, hjust=0, vjust=1, gp=gp), t=1, l=1, b=1, r=2, clip="off", z=100, name="A")
gtab = gtable_add_grob(gtab, textGrob("B", x=0.51, y=0.99, hjust=0, vjust=1, gp=gp), t=1, l=1, b=1, r=2, clip="off", z=101, name="B")
gtab = gtable_add_grob(gtab, textGrob("C", x=1.01, y=0.99, hjust=0, vjust=1, gp=gp), t=1, l=1, b=1, r=2, clip="off", z=102, name="C")

res=400
width=7.0
height=2.0
ptsize=10
tiff("3way_erate_400.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()
