#!/usr/bin/Rscript

#Crosslink
#Copyright (C) 2016  NIAB EMR
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along
#with this program; if not, write to the Free Software Foundation, Inc.,
#51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#contact:
#robert.vickerstaff@emr.ac.uk
#Robert Vickerstaff
#NIAB EMR
#New Road
#East Malling
#WEST MALLING
#ME19 6BJ
#United Kingdom

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
