#!/usr/bin/Rscript

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
                "hk_score",
                "mapping_score"))
                
#dat$GIBBS_PROB_UNORDERED = 1.0 - (dat$GIBBS_PROB_SEQUENTIAL + dat$GIBBS_PROB_UNIDIR)

dat$logmap = log10(1.0 - dat$mapping_score)

plt = ggplot(dat, aes(x = factor(GIBBS_TWOPT_2), y = hk_score)) +
    geom_boxplot() +
    ylab("hk imputation score") +
    xlab("twopt 2")
ggsave(file="figs/twopt2_vs_hkscore.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_TWOPT_2), y = logmap)) +
    geom_boxplot() +
    ylab("log10(1 - mappingscore)") +
    xlab("twopt 2")
ggsave(file="figs/twopt2_vs_logmap.png",plot=plt,dpi=600)

