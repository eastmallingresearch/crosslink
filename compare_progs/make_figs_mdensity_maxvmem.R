#!/usr/bin/Rscript

#Crosslink, Copyright (C) 2016  NIAB EMR

#compare performance versus marker density

library(ggplot2)
library(scales)
library(gridExtra)
library(gtable)
library(grid) # for R 3.2.3 for gpar

setwd("~/rjv_mnt/cluster/crosslink/ploscompbiol_data/mdensity_simdata/figs")

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
          sd   = sd     (xx[[col]], na.rm=na.rm)
        )
      },
      measurevar
    )

    # Rename the "mean" column    
    datac <- rename(datac, c("mean" = measurevar))

    datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean

    # Confidence interval multiplier for standard error
    # Calculate t-statistic for confidence interval: 
    # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
    ciMult <- qt(conf.interval/2 + .5, datac$N-1)
    datac$ci <- datac$se * ciMult

    return(datac)
}

theme = theme(
  #panel.background = element_rect(fill="white"),
  #axis.ticks = element_line(colour=NA),
  #panel.grid = element_line(colour="grey"),
  axis.text.y = element_text(colour="black"),
  axis.text.x = element_text(colour="black",angle=45,hjust=1),
  text = element_text(size=8, family="Arial"),
  title = element_text(size=12, family="Arial")
)

#system("cat ../*/score  | sed 's/sample_data\\///g' | sed 's/_[0-9][0-9]*//g' > mdensity_data")

dat = read.table("maxvmem_stats_mod",col.names=c("algorithm","density","maxvmem"))
dat$n_markers = dat$density * 100

datsum <- summarySE(dat, measurevar="maxvmem", groupvars=c("algorithm","n_markers"))

#log error versus algorithm
p1 = ggplot(datsum, aes(x=n_markers, y=maxvmem, colour=algorithm)) + 
    geom_errorbar(aes(ymin=maxvmem-se, ymax=maxvmem+se), width=.1) +
    geom_line() +
    geom_point() +
    ylab("Max. Memory") +
    xlab("Markers") +
    scale_y_log10()
# + theme


plots = matrix(list(ggplotGrob(p1),ggplotGrob(p1)),nrow=1,byrow=TRUE)
w=unit(c(1,1),"null")
h=unit(c(1),"null")
z=matrix(c(1,2),nrow=1)
gp = gpar(lwd = 3, fontsize = 18)
gtab = gtable_matrix("X",grobs=plots,widths=w,heights=h,z=z)
gtab = gtable_add_grob(gtab, textGrob("A", x=0.01, y=0.98, hjust=0,vjust=1,gp=gp), t=1, l=1, b=1, r=2, clip="off", z=100, name="A")
gtab = gtable_add_grob(gtab, textGrob("B", x=0.51, y=0.98, hjust=0,vjust=1,gp=gp), t=1, l=1, b=1, r=2, clip="off", z=101, name="B")

res=300
width=7.5
height=3.25
tiff("maxvmem.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white")
grid.draw(gtab)
dev.off()

ggsave("maxvmem.png")
