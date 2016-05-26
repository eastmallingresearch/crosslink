#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

# test GA_USE_MST with correlated samples ANOVA
# does the mapping score differ between the three treatments (GA_USE_MST)
# given that the same sample was used for each treatment (SAMPLE_DIR)

#library(ggplot2)

setwd("~/crosslink/ploscompbiol_data/simdata/figs")
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
                "map"))


#convert to factors
dat$samp = factor(dat$SAMPLE_DIR)
dat$unidir = factor(dat$GIBBS_PROB_UNIDIR)


cat("============correlated samples 1-factor anova")
aov.out = aov(map ~ unidir + Error(samp/unidir), data=dat)
summary(aov.out)

cat("============pairwise t tests with bonferroni correction")
with(dat, pairwise.t.test(x=map, g=unidir, p.adjust.method="bonf", paired=T))

#cat("============2-factor anova")
#aov.tbys = aov(map ~ k + samp, data=dat)
#summary(aov.tbys)

#cat("============Tukey honest sig diff")
#TukeyHSD(aov.tbys, which="k")
 
k1 = subset(dat,k==1)
k3 = subset(dat,k==3)

mean(k1$knn)
sd(k1$knn)
mean(k3$knn)
sd(k3$knn)
   
