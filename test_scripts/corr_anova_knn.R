#!/usr/bin/Rscript
#Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details

# test GA_USE_MST with correlated samples ANOVA
# does the mapping score differ between the three treatments (GA_USE_MST)
# given that the same sample was used for each treatment (SAMPLE_DIR)

#library(ggplot2)

setwd("~/crosslink/ploscompbiol_data/simdata/figs")
system("cat ../test_knn/*/score > knn_data")
dat = read.table("knn_data",col.names=c("k","samp","typeerr","group","phase","knn","map"))


#convert to factors
dat$samp = factor(dat$samp)
dat$k = factor(dat$k)


cat("============correlated samples 1-factor anova")
aov.out = aov(map ~ k + Error(samp/k), data=dat)
summary(aov.out)

cat("============pairwise t tests with bonferroni correction")
with(dat, pairwise.t.test(x=map, g=k, p.adjust.method="bonf", paired=T))

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
   
