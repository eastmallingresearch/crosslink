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
                
dat$GIBBS_PROB_UNORDERED = 1.0 - (dat$GIBBS_PROB_SEQUENTIAL + dat$GIBBS_PROB_UNIDIR)

plt = ggplot(dat, aes(x = factor(GIBBS_SAMPLES), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="samples"))
ggsave(file="figs/samples.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_BURNIN), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="burnin"))
ggsave(file="figs/burnin.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_PROB_SEQUENTIAL), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="p_sequential"))
ggsave(file="figs/p_sequential.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_PROB_UNIDIR), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="p_unidir"))
ggsave(file="figs/p_unidir.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_PROB_UNORDERED), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="p_unordered"))
ggsave(file="figs/p_unordered.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_MIN_PROB_1), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="minprob1"))
ggsave(file="figs/minprob1.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_MIN_PROB_2), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="minprob2"))
ggsave(file="figs/minprob2.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_TWOPT_1), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="twopoint1"))
ggsave(file="figs/twopoint1.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GIBBS_TWOPT_2), y = hk_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="twopoint2"))
ggsave(file="figs/twopoint2.png",plot=plt,dpi=600)
