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


#compare mapping performance between programs / modes of operation

library(ggplot2)

setwd("/home/vicker/crosslink/ploscompbiol_data/compare_simdata")

system("cat */score > all_scores")

dat = read.table("all_scores",col.names=c("algorithm","sample","t_real","t_user","t_sys","accuracy"))
dat$t_cpu = dat$t_user + dat$t_sys
dat$err = 1.0 - dat$accuracy

#mapping score versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = accuracy)) +
    geom_boxplot() +
    ylab("mapping score") +
    xlab("algorithm")
ggsave(file="figs/accuracy_vs_algorithm.png",plot=plt,dpi=600)

#log error versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = err)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("error") +
    xlab("algorithm")
ggsave(file="figs/logerr_vs_algorithm.png",plot=plt,dpi=600)

#cpu time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_cpu)) +
    geom_boxplot() +
    ylab("cpu time (secs)") +
    xlab("algorithm")
ggsave(file="figs/cputime_vs_algorithm.png",plot=plt,dpi=600)

#log time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_cpu)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("cpu time (secs)") +
    xlab("algorithm")
ggsave(file="figs/logcputime_vs_algorithm.png",plot=plt,dpi=600)

#log real time versus algorithm
plt = ggplot(dat, aes(x = factor(algorithm), y = t_real)) +
    geom_boxplot() +
    scale_y_log10() +   
    ylab("real time (secs)") +
    xlab("algorithm")
ggsave(file="figs/logrealtime_vs_algorithm.png",plot=plt,dpi=600)
