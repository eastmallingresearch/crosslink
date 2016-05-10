#!/usr/bin/Rscript
#compare performance versus minlod used for grouping and whether
#approx ordering prioritises nonhk edges or not

library(ggplot2)
library(gridExtra)

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

#minlod versus grouping score
p1 = ggplot(dat, aes(x = factor(minlod), y = group)) +
    geom_boxplot() +
    ylab("Grouping Score") +
    xlab("Grouping LOD") +
    theme

#minlod versus phasing accuracy
p2 = ggplot(dat, aes(x = factor(minlod), y = phase)) +
    geom_boxplot() +
    ylab("Phasing Score") +
    xlab("Grouping LOD") +
    theme

#minlod versus type correction score
p3 = ggplot(dat, aes(x = factor(minlod), y = typeerr)) +
    geom_boxplot() +
    ylab("Type Correction Score") +
    xlab("Grouping LOD") +
    theme

#minlod + nonhk versus mapping score
levels(dat$nonhk) <- c("No Prioritisation","Prioritise Non-hkxhk")
p4 = ggplot(dat, aes(x = factor(minlod), y = 1 - map)) +
    geom_boxplot() +
    scale_y_log10() +
    facet_wrap(~nonhk) +
    ylab("1 - Mapping Score") +
    xlab("Grouping LOD") +
    theme

res=300
width=7.5
height=7.5
ptsize=10
tiff("2.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.arrange(p1,p2,p3,p4)
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
    xlab("Probability Unidirectional Mode") +
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

p3 = ggplot(dat, aes(x = factor(GIBBS_TWOPT_2), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Twopt2") +
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

p4 = ggplot(dat, aes(x = factor(GIBBS_MIN_PROB_2), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Minprob2") +
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

p5 = ggplot(dat, aes(x = factor(GIBBS_SAMPLES), y = hk_score)) +
    geom_boxplot() +
    ylab("hk Imputation Score") +
    xlab("Gibbs Samples") +
    theme

res=300
width=7.5
height=7.5
ptsize=10
tiff("3.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.arrange(p1,p2,p3,p4,p5,ncol=2)
dev.off()

system("cat ../test_mincount/*/score > mincount_data")
dat = read.table("mincount_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p1 = ggplot(dat, aes(x = factor(HOMEO_MINCOUNT), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    xlab("Mincount") +
    theme

system("cat ../test_minlod/*/score > minlod_data")
dat = read.table("minlod_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p2 = ggplot(dat, aes(x = factor(HOMEO_MINLOD), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    xlab("MinLOD") +
    theme

system("cat ../test_maxlod/*/score > maxlod_data")
dat = read.table("maxlod_data",col.names=c(
                "HOMEO_MINCOUNT",
                "HOMEO_MINLOD",
                "HOMEO_MAXLOD",
                "SAMPLE_DIR",
                "crosslg_score"))
                
p3 = ggplot(dat, aes(x = factor(HOMEO_MAXLOD), y = crosslg_score)) +
    geom_boxplot() +
    ylab("Cross Linkage Group Detection") +
    xlab("MaxLOD") +
    theme

res=300
width=7.5
height=7.5
ptsize=10
tiff("4.tiff",res=res,width=width*res,height=height*res,compression="lzw",bg="white",pointsize=ptsize)
grid.arrange(p1,p2,p3,ncol=2)
dev.off()
