#!/usr/bin/Rscript

library(ggplot2)

#cat */score > all_scores

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
                
dat$GA_PROB_SEGINV = 1.0 - (dat$GA_PROB_HOP + dat$GA_PROB_MOVE)

plt = ggplot(dat, aes(x = GA_ITERS, y = mapping_score)) +
    geom_point() +
    guides(fill=guide_legend(title="iters"))
ggsave(file="figs/iters.png",plot=plt,dpi=600)

dat$Q_GA_ITERS = floor(dat$GA_ITERS / 10000.0)
plt = ggplot(dat, aes(x = factor(Q_GA_ITERS), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="q_iters"))
ggsave(file="figs/q_iters.png",plot=plt,dpi=600)

plt = ggplot(dat, aes(x = factor(GA_USE_MST), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="usemst"))
ggsave(file="figs/usemst.png",plot=plt,dpi=600)

dat$Q_GA_PROB_HOP = floor(dat$GA_PROB_HOP * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_PROB_HOP), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="probhop"))
ggsave(file="figs/probhop.png",plot=plt,dpi=600)

dat$Q_GA_MAX_HOP = floor(dat$GA_MAX_HOP * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_MAX_HOP), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="maxhop"))
ggsave(file="figs/maxhop.png",plot=plt,dpi=600)

dat$Q_GA_PROB_MOVE = floor(dat$GA_PROB_MOVE * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_PROB_MOVE), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="probmove"))
ggsave(file="figs/probmove.png",plot=plt,dpi=600)

dat$Q_GA_MAX_MVSEG = floor(dat$GA_MAX_MVSEG * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_MAX_MVSEG), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="maxmvseg"))
ggsave(file="figs/maxmvseg.png",plot=plt,dpi=600)

dat$Q_GA_MAX_MVDIST = floor(dat$GA_MAX_MVDIST * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_MAX_MVDIST), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="maxmvdist"))
ggsave(file="figs/maxmvdist.png",plot=plt,dpi=600)

dat$Q_GA_PROB_INV = floor(dat$GA_PROB_INV * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_PROB_INV), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="probinv"))
ggsave(file="figs/probinv.png",plot=plt,dpi=600)

dat$Q_GA_PROB_SEGINV = floor(dat$GA_PROB_SEGINV * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_PROB_SEGINV), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="probseginv"))
ggsave(file="figs/probseginv.png",plot=plt,dpi=600)

dat$Q_GA_MAX_SEG = floor(dat$GA_MAX_SEG * 10.0)
plt = ggplot(dat, aes(x = factor(Q_GA_MAX_SEG), y = mapping_score)) +
    geom_boxplot() +
    guides(fill=guide_legend(title="maxseg"))
ggsave(file="figs/maxseg.png",plot=plt,dpi=600)
