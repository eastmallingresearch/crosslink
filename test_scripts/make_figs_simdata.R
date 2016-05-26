#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#compare performance versus minlod used for grouping and whether
#approx ordering prioritises nonhk edges or not

library(ggplot2)
library(gridExtra)
library(gtable)

setwd("~/crosslink/ploscompbiol_data/simdata/figs")

theme = theme(
  #panel.background = element_rect(fill="white"),
  #axis.ticks = element_line(colour=NA),
  #panel.grid = element_line(colour="grey"),
  axis.text.y = element_text(colour="black"),
  axis.text.x = element_text(colour="black"),
  text = element_text(size=8, family="Arial"),
  title = element_text(size=12, family="Arial")
)

#=======test_group
system("cat ../test_group/*/score > group_data")
dat = read.table("group_data",col.names=c("minlod","nonhk","sample","typeerr","group","phase","knn","map"))
#dat$err = 1.0 - dat$map
dat$nonhk = factor(dat$nonhk)

#minlod + nonhk versus mapping score
levels(dat$nonhk) <- c("No Prioritisation","Prioritise Non-hkxhk")
p4 = ggplot(dat, aes(x = factor(minlod), y = 1 - map)) +
    geom_boxplot() +
    scale_y_log10() +
    facet_wrap(~nonhk) +
    ylab("1 - Mapping Score") +
    xlab("Grouping LOD (min_lod)") +
    theme

#retain only the nonhk=1 data
#approx ordering does not affect grouping, phasing or type error correction
#therefore no need to include them (although with seed=0 they can as two independent reps)
dat = subset(dat, nonhk=="Prioritise Non-hkxhk")

#minlod versus grouping score
p1 = ggplot(dat, aes(x = factor(minlod), y = group)) +
    geom_boxplot() +
    ylab("Grouping Score") +
    xlab("Grouping LOD (min_lod)") +
    theme

#minlod versus phasing accuracy
p2 = ggplot(dat, aes(x = factor(minlod), y = phase)) +
    geom_boxplot() +
    ylab("Phasing Score") +
    xlab("Grouping LOD (min_lod)") +
    theme

#minlod versus type correction score
p3 = ggplot(dat, aes(x = factor(minlod), y = typeerr)) +
    geom_boxplot() +
    ylab("Type Correction Score") +
    xlab("Grouping LOD (min_lod)") +
    theme


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
tiff("2.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()

system("cat ../test_knn/*/score > knn_data")
dat = read.table("knn_data",col.names=c("k","sample","typeerr","group","phase","knn","map"))
p1 = ggplot(dat, aes(x = factor(k), y = knn)) +
    geom_boxplot() +
    ylab("knn Imputation Score") +
    xlab("k (knn)") +
    theme

system("cat ../test_mincount/*/score > mincount_data")
dat = read.table("mincount_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p2 = ggplot(dat, aes(x = factor(HOMEO_MINCOUNT), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    scale_y_continuous(limits = c(0.0,1.0)) +
    xlab("Mincount (homeo_mincount)") +
    theme

system("cat ../test_minlod/*/score > minlod_data")
dat = read.table("minlod_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p3 = ggplot(dat, aes(x = factor(HOMEO_MINLOD), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    scale_y_continuous(limits = c(0.0,1.0)) +
    xlab("MinLOD (homeo_minlod)") +
    theme

system("cat ../test_maxlod/*/score > maxlod_data")
dat = read.table("maxlod_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p4 = ggplot(dat, aes(x = factor(HOMEO_MAXLOD), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    scale_y_continuous(limits = c(0.0,1.0)) +
    xlab("MaxLOD (homeo_maxlod)") +
    theme

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
tiff("3.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()

#=================test_unidir
system("cat ../test_unidir/*/score > unidir_data")
dat = read.table("unidir_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "mapping_score"))

p1 = ggplot(dat, aes(x = factor(GIBBS_PROB_UNIDIR), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Prob. Unidirectional (gibbs_prob_unidir)") +
    theme

system("cat ../test_twopt/*/score > twopt_data")
dat = read.table("twopt_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "mapping_score"))

p2 = ggplot(dat, aes(x = factor(GIBBS_TWOPT_2), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Twopt2 (gibbs_twopt_2)") +
    theme

system("cat ../test_minprob/*/score > minprob_data")
dat = read.table("minprob_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "mapping_score"))
                
dat = subset(dat, GIBBS_MIN_PROB_2 != 0.5)
dat = subset(dat, GIBBS_MIN_PROB_2 != 0.4)

p3 = ggplot(dat, aes(x = factor(GIBBS_MIN_PROB_2), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Minprob2 (gibbs_min_prob_2)") +
    theme

system("cat ../test_gibbssamples/*/score > gibbs_data")
dat = read.table("gibbs_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "mapping_score"))
                
dat = subset(dat, GIBBS_SAMPLES != 1)

p4 = ggplot(dat, aes(x = factor(GIBBS_SAMPLES), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Gibbs Samples (gibbs_samples)") +
    theme

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
tiff("4.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()


system("cat ../test_gaiters/*/score > gaiters_data")
dat = read.table("gaiters_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "map"))
                
p1 = ggplot(dat, aes(x = factor(GA_ITERS), y = map)) +
    geom_boxplot() +
    ylab("Mapping Score") +
    scale_y_continuous(limits = c(0.993,0.997)) +
    xlab("GA Iterations Per Cycle (ga_iters)") +
    theme

system("cat ../test_gausemst/*/score > gausemst_data")
dat = read.table("gausemst_data",col.names=c(
                "GA_GIBBS_CYCLES",
                "GA_ITERS",
                "GA_USE_MST",
                "GA_MINLOD",
                "GA_MST_NONHK",
                "GA_OPTIMISE_METH",
                "GA_PROB_HOP",
                "GA_MAX_HOP",
                "GA_PROB_MOVE",
                "GA_MAX_MVSEG",
                "GA_MAX_MVDIST",
                "GA_PROB_INV",
                "GA_MAX_SEG",
                "GIBBS_SAMPLES",
                "GIBBS_BURNIN",
                "GIBBS_PERIOD",
                "GIBBS_PROB_SEQUENTIAL",
                "GIBBS_PROB_UNIDIR",
                "GIBBS_MIN_PROB_1",
                "GIBBS_MIN_PROB_2",
                "GIBBS_TWOPT_1",
                "GIBBS_TWOPT_2",
                "SAMPLE_DIR",
                "MYUID",
                "hk_score",
                "map"))

dat$GA_USE_MST = factor(dat$GA_USE_MST)
levels(dat$GA_USE_MST) <- c("None","All But Last","All")
p2 = ggplot(dat, aes(x = factor(GA_USE_MST), y = map)) +
    geom_boxplot() +
    ylab("Mapping Score") +
    scale_y_continuous(limits = c(0.993,0.997)) +
    xlab("Use MST Which Cycle (ga_use_mst)") +
    theme

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
ptsize=10
tiff("5.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.draw(gtab)
dev.off()
