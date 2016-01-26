#!/usr/bin/Rscript

library(ggplot2)


# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}


#system("cat ./compare_progs/compare_*_stats | awk 'NF==12' > ./compare_progs/all_stats")

# ====== comparison between crosslink and tmap and onemap: small map
dat = read.table("./compare_progs/all_stats",col.names=c("program","error","markers","density","replicate","spearman","pearson","proportion","real","user","system","expansion"))
dat$score = 1.0 - dat$pearson

give.n1 = function(dat)
{
  return(c(y = 0.0, label = length(dat))) 
}

give.n2 = function(dat)
{
  return(c(y = 0.5, label = length(dat))) 
}

#change order of programs
dat$program <- factor(dat$program, levels = dat$program[order(c(2,3,4,1,5))])

denlist = c(0.1,1,10)
plist = c()

for (i in 1:3)
{
    den = denlist[i][1]

    #pearson - map colinearity
    plist[[length(plist)+1]] = ggplot(dat[dat$density == den,], aes(x = program, y = pearson, fill = program)) +
        geom_boxplot() +
        stat_summary(fun.data = give.n1, geom = "text", fun.y = 0.0, size = 3) +
        facet_grid(markers ~ error) +
        #scale_y_log10() +
        scale_fill_manual(values = c("grey","pink","green","cyan","purple")) +
        theme(axis.ticks = element_blank(), axis.text.x = element_blank(), axis.title.x = element_blank()) +
        theme(axis.text.y = element_text(colour="black")) +
        guides(fill=guide_legend(title="Program")) +
        ylab("|Pearson correlation|")
        
    #save individual plot
    ggsave(file=sprintf("figs/compare_pearson_%.1f.png",den),plot=plist[[length(plist)]],dpi=600)
}

multiplot(plist[1], plist[2], plist[3], cols=3)
ggsave(file=sprintf("figs/compare_pearson_multi.png",den),dpi=600)

