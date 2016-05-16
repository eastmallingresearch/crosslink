#!/usr/bin/Rscript


#https://ww2.coastal.edu/kingw/statistics/R-tutorials/repeated.html

setwd("~/crosslink/ploscompbiol_data/simdata/figs")
system("cat ../test_group/*/score > group_data")

dat = read.table("group_data",col.names=c("minlod","nonhk","sample","typeerr","group","phase","knn","map"))

dat$nonhk = factor(dat$nonhk)
dat$sample = factor(dat$sample)

dat = subset(dat,minlod==9|minlod==11|minlod==14)

dat0 = subset(dat,nonhk==0)
dat1 = subset(dat,nonhk==1)

dat0 = dat0[ order(dat0$sample,dat0$minlod), ]
dat1 = dat1[ order(dat1$sample,dat1$minlod), ]

mean(dat0$map)
sd(dat0$map)
mean(dat1$map)
sd(dat1$map)

t.test(dat0$map,dat1$map, paired=TRUE)

#cat("============correlated samples 1-factor anova")
#aov.out = aov(map ~ nonhk + Error(sample/nonhk), data=dat)
#summary(aov.out)

#cat("============pairwise t tests with bonferroni correction")
#with(dat, pairwise.t.test(x=map, g=nonhk, p.adjust.method="bonf", paired=T))

#cat("============2-factor anova")
#aov.tbys = aov(map ~ nonhk + sample, data=dat)
#summary(aov.tbys)

#cat("============Tukey honest sig diff")
#TukeyHSD(aov.tbys, which="nonhk")
    
