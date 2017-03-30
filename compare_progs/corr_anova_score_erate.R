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

#library(ggplot2)
#library(dplyr)

setwd("~/crosslink/ploscompbiol_data/erate_simdata/figs")

#system("cat */score > all_scores")
dat = read.table("erate_4way",col.names=c("algorithm","erate","t_user","t_sys","corr","missing","expansion"))

dat = subset(dat, algorithm!="joinmap")
dat$algorithm = factor(dat$algorithm)
dat$erate = factor(dat$erate)

for (ee in levels(dat$erate))
{
    dat2 = subset(dat,erate==ee)
    #print(dat2)
    
    cat(ee,'\n')
    #cat("============1-factor anova\n")
    #aov.out = aov(corr ~ algorithm , data=dat2)
    #print(summary(aov.out))

    cat("============pairwise t tests with bonferroni correction\n")
    print(with(dat2, pairwise.t.test(x=corr, g=algorithm, p.adjust.method="bonf", paired=T)))
}
