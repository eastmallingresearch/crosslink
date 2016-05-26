#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

# test GA_USE_MST with correlated samples ANOVA
# does the mapping score differ between the three treatments (GA_USE_MST)
# given that the same sample was used for each treatment (SAMPLE_DIR)

#library(ggplot2)

#collect all results
setwd("~/crosslink/ploscompbiol_data/simdata/figs")
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
                "hk",
                "map"))

#convert to factors
dat$SAMPLE_DIR = factor(dat$SAMPLE_DIR)
dat$GA_USE_MST = factor(dat$GA_USE_MST)

cat("============correlated samples 1-factor anova")
aov.out = aov(map ~ GA_USE_MST + Error(SAMPLE_DIR/GA_USE_MST), data=dat)
summary(aov.out)

cat("============pairwise t tests with bonferroni correction")
with(dat, pairwise.t.test(x=map, g=GA_USE_MST, p.adjust.method="bonf", paired=T))

mean(subset(dat,GA_USE_MST==0)$map)
mean(subset(dat,GA_USE_MST==3)$map)
mean(subset(dat,GA_USE_MST==5)$map)

sd(subset(dat,GA_USE_MST==0)$map)
sd(subset(dat,GA_USE_MST==3)$map)
sd(subset(dat,GA_USE_MST==5)$map)

#cat("============2-factor anova")
#aov.tbys = aov(map ~ GA_USE_MST + SAMPLE_DIR, data=dat)
#summary(aov.tbys)

#cat("============Tukey honest sig diff")
#TukeyHSD(aov.tbys, which="GA_USE_MST")
    
