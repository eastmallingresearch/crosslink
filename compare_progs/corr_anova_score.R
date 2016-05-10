#!/usr/bin/Rscript

library(ggplot2)

setwd("/home/vicker/crosslink/ploscompbiol_data/compare_simdata")

system("cat */score > all_scores")

dat = read.table("all_scores",col.names=c("algorithm","sample","t_real","t_user","t_sys","accuracy"))

#convert to factors
dat$sample = factor(dat$sample)
dat$algorithm = factor(dat$algorithm)

cat("============correlated samples 1-factor anova\n")
aov.out = aov(accuracy ~ algorithm + Error(sample/algorithm), data=dat)
summary(aov.out)

cat("============pairwise t tests with bonferroni correction\n")
with(dat, pairwise.t.test(x=accuracy, g=algorithm, p.adjust.method="bonf", paired=T))

cat("============2-factor anova\n")
aov.tbys = aov(accuracy ~ algorithm + sample, data=dat)
summary(aov.tbys)

cat("============Tukey honest sig diff\n")
TukeyHSD(aov.tbys, which="algorithm")
