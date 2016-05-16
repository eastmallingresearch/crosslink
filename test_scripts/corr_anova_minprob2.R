#!/usr/bin/Rscript


#library(ggplot2)

#collect all results
setwd("~/crosslink/ploscompbiol_data/simdata/figs")
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
                "hk",
                "map"))
                
#convert to factors
dat$SAMPLE_DIR = factor(dat$SAMPLE_DIR)
#dat$treatment = factor(sprintf("%.1f_%.1f",dat$GIBBS_TWOPT_1,dat$GIBBS_TWOPT_2))
dat$treatment = factor(dat$GIBBS_MIN_PROB_2)

cat("============correlated samples 1-factor anova")
aov.out = aov(hk ~ treatment + Error(SAMPLE_DIR/treatment), data=dat)
summary(aov.out)

#cat("============pairwise t tests with bonferroni correction")
with(dat, pairwise.t.test(x=hk, g=treatment, p.adjust.method="bonf", paired=T))

cat("============2-factor anova")
aov.tbys = aov(hk ~ treatment + SAMPLE_DIR, data=dat)
summary(aov.tbys)

cat("============Tukey honest sig diff")
TukeyHSD(aov.tbys, which="treatment")

