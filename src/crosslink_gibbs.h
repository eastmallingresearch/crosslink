//Crosslink, Copyright (C) 2016  NIAB EMR
#ifndef _RJV_CROSSLINK_GIBBS_H_
#define _RJV_CROSSLINK_GIBBS_H_

#include "crosslink_common.h"

void gibbs_impute(struct conf*c);
unsigned count_hkerrors(struct conf*c);
unsigned count_hkmissing(struct conf*c);
unsigned gibbs_count_events(struct conf*c,VARTYPE*d1,VARTYPE*d2);
double gibbs_twopoint(struct conf*c,struct marker*m1,struct marker*m2,unsigned x);
void gibbs_init(struct conf*c);
unsigned gibbs_count_recombs(struct conf*c);
void gibbs_sample(struct conf*c);
double gibbs_calc_prob(struct conf*c,struct hk*p,VARTYPE adj_state,unsigned x,unsigned R,double rf_2pt);
void gibbs_iterate_inner(struct conf*c,struct hk*p);
int gibbs_comp(const void*phk1, const void*phk2);
void gibbs_iterate(struct conf*c,unsigned iters,unsigned burnin_flag);
unsigned gibbs_choose_state(struct conf*c,double p_mat_prev,double p_mat_next,double p_pat_prev,double p_pat_next);
void gibbs_setstate(struct conf*c);

#endif
