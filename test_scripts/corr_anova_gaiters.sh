#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

library(ggplot2)

system("cat */score > all_scores")

##21,22,25
dat = read.table("all_scores",col.names=c(
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

#make sure sample_dir is a factor
dat$SAMPLE_DIR = factor(dat$SAMPLE_DIR)
dat$GA_ITERS = factor(dat$GA_ITERS)

cat("============correlated samples 1-factor anova\n")
aov.out = aov(map ~ GA_ITERS + Error(SAMPLE_DIR/GA_ITERS), data=dat)
summary(aov.out)

cat("============pairwise t tests with bonferroni correction\n")
with(dat, pairwise.t.test(x=map, g=GA_ITERS, p.adjust.method="bonf", paired=T))

cat("============2-factor anova\n")
aov.tbys = aov(map ~ GA_ITERS + SAMPLE_DIR, data=dat)
summary(aov.tbys)

cat("============Tukey honest sig diff\n")
TukeyHSD(aov.tbys, which="GA_ITERS")
