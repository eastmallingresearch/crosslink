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

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/mdensity_simdata/figs")

lw = 0.3
ps = 0.8
ew = 0.05

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

#plot approx mem usage
dat2 = read.table("maxvmem_stats_mod",col.names=c("algorithm","density","maxvmem"))
dat2$n_markers = dat2$density * 100

datsum2 <- summarySE(dat2, measurevar="maxvmem", groupvars=c("algorithm","n_markers"))

#==============>memory
p1 = ggplot(datsum2, aes(x=n_markers, y=maxvmem, colour=algorithm, shape=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum2$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw) +
    geom_line(size=lw) +
    geom_point(size=ps) +
    ylab("Approx. Max. Memory") +
    xlab("Number of Markers") +
    scale_y_log10() +
    scale_x_log10()
    #theme(legend.position = "none")

dat = read.table("mdensity_4way",col.names=c("algorithm","density","t_user","t_sys","corr","missing","expansion"))
dat$t_cpu = dat$t_user + dat$t_sys
dat$t_hrs = dat$t_cpu / 3600
dat$err = 1 - dat$corr
dat$n_markers = dat$density * 100


#===============ordering
datsum <- summarySE(dat, measurevar="err", groupvars=c("algorithm","n_markers"))
p2 = ggplot(datsum, aes(x=n_markers, y=err, colour=algorithm, shape=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw) +
    geom_line(size=lw) +
    geom_point(size=ps) +
    ylab("Ordering Error (1 - Corr. Coeff)") +
    xlab("Number of Markers") +
    scale_x_log10() +
    scale_y_log10(breaks=c(0.001,0.01,0.1,1.0)) +
    theme(legend.position = "none")


#============>time
datsum <- summarySE(dat, measurevar="t_hrs", groupvars=c("algorithm","n_markers"))
p3 = ggplot(datsum, aes(x=n_markers, y=t_hrs, colour=algorithm, shape=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw) +
    geom_line(size=lw) +
    geom_point(size=ps) +
    ylab("CPU Time (hrs)") +
    xlab("Number of Markers") +
    scale_x_log10() +
    scale_y_log10(breaks=c(1e-5,1e-4,1e-3,1e-2,1e-1,1e0,1e1,1e2,1e3)) +
    theme(legend.position = "none")

#============>expansion
datsum <- summarySE(dat, measurevar="expansion", groupvars=c("algorithm","n_markers"))
p4 = ggplot(datsum, aes(x=n_markers, y=expansion, colour=algorithm, shape=algorithm)) + 
    scale_shape_manual(values=1:nlevels(datsum$algorithm)) +
    geom_errorbar(aes(ymin=lq, ymax=uq), width=ew, size=lw) +
    geom_line(size=lw) +
    geom_point(size=ps) +
    ylab("Map Expansion") +
    xlab("Number of Markers") +
    scale_y_log10(breaks=c(1,10,100,1000)) +
    scale_x_log10() +
    theme(legend.position = "none")


plots = matrix(list(ggplotGrob(p1),ggplotGrob(p2),ggplotGrob(p3),ggplotGrob(p4)),nrow=2,byrow=TRUE)
w=unit(c(1,1),"null")
h=unit(c(1,1),"null")
z=matrix(c(1,2,3,4),nrow=2)
gp = gpar(lwd = 3, fontsize = 18)
gtab = gtable_matrix("X",grobs=plots,widths=w,heights=h,z=z)
gtab = gtable_add_grob(gtab, textGrob("A", x=0.01, y=0.99, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2,r=2,clip="off",z=100,name="A")
gtab = gtable_add_grob(gtab, textGrob("B", x=0.51, y=0.99, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=101,name="B")
gtab = gtable_add_grob(gtab, textGrob("C", x=0.01, y=0.49, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=102,name="C")
gtab = gtable_add_grob(gtab, textGrob("D", x=0.51, y=0.49, hjust=0,vjust=1,gp=gp), t=1, l=1, b=2, r=2, clip="off",z=103,name="D")

res=300
width=7.5
height=7.5
ptsize=10
tiff("4way_mdensity.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()

pp = ggplot(dat, aes(x = algorithm, y = err, fill=algorithm)) +
    geom_boxplot(outlier.size=0.1,lwd=0.2) +
    scale_y_log10(breaks=c(.001,.01,.1,1)) +
    scale_x_discrete(position="top") +
    facet_wrap(~factor(n_markers)) +
    ylab("Ordering Error (1 - Corr. Coeff)") +
    xlab("Number of Markers") + 
    theme(#axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          text = element_text(size=7, family="Arial"),
          title = element_text(size=8, family="Arial"),
          legend.key.size=unit(.1,"in")
        )
    #theme(strip.background = element_blank(),
    #   strip.text.x = element_blank())
    #xlab("erate") #+
    #theme

res=450
width=3.75
height=3.75
ggsave("mdensity_err_facet.tiff",width=width,height=height,units="in",dpi=res,compression="lzw")

