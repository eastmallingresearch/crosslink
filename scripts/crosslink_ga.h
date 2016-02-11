#ifndef _RJV_CROSSLINK_GA_H_
#define _RJV_CROSSLINK_GA_H_

#include "crosslink_common.h"

unsigned lookup_2pt(struct conf*c,struct marker*m1,struct marker*m2,unsigned x);
double calc_rf_hk_implicit(struct conf*c,VARTYPE*m1,VARTYPE*m2,unsigned c0);
double calc_rf_hk_explicit(struct conf*c,VARTYPE*m1,VARTYPE*m2);
unsigned lookup_mpt(struct conf*c,struct marker*m1,struct marker*m2,unsigned x);
unsigned count64(uint64_t val);
unsigned calc_events(struct conf*c,struct marker**array);
unsigned local_events2(struct conf*c,struct marker**array,unsigned x,const int*_brk,int nbrk);
unsigned dec_events(struct conf*c,struct mutation*op,struct marker**dst);
unsigned inc_events(struct conf*c,struct mutation*op,struct marker**dst);
void generate_mutation(struct conf*c,struct mutation*op);
void accept_mutation(struct conf*c,struct mutation*op);
void undo_mutation(struct conf*c,struct mutation*op);
void apply_mutation(struct mutation*op,struct marker**dst,struct marker**src);
void order_map(struct conf*c);
void ga_build_elist(struct conf*c);
void mst_approx_order(struct conf*c);
int ecomp_mapdist_only(const void*_p1, const void*_p2);
double calc_2pt_rf(struct conf*c,struct marker*m1,struct marker*m2,unsigned x);

#endif
