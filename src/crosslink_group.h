//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#ifndef _RJV_CROSSLINK_GROUP_H_
#define _RJV_CROSSLINK_GROUP_H_

#include "crosslink_common.h"

void add_edge2(struct earray*e,struct marker*m1,struct marker*m2,double lod,double rf,unsigned cxr_flag,double cm,unsigned nonhk);
void add_edge(struct conf*c,struct marker*m1,struct marker*m2,double lod,double rf,unsigned cxr_flag,double cm,unsigned nonhk);
void calc_rflod_simple(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,double*_lod,double*_rf);
void calc_rflod_hk(struct conf*c,VARTYPE*m1,VARTYPE*m2,double*_lod,double*_rf,unsigned*_cxr_flag);
void build_elist(struct conf*c,struct lg*p,struct earray*e);
int ecomp_func(const void*_p1, const void*_p2);
int ecomp_mapdist_nonhk(const void*_p1, const void*_p2);
void sort_elist(struct earray*e);
struct marker*find_group(struct marker*m);
unsigned union_groups(struct marker*m1,struct marker*m2);
void form_groups(struct conf*c,struct lg*p,struct earray*ea,struct map*mp);
void phase_markers(struct conf*c,struct lg*p,struct earray*ea,unsigned x);
void dfs_phase(struct conf*c,struct marker*m,unsigned phase,unsigned x);
void order_markers(struct conf*c,unsigned nmark,struct marker**array,unsigned nedge,struct edge**elist,unsigned x);
void order_markers2(struct conf*c,struct lg*p,struct earray*ea,unsigned x);
void dfs_assign(struct marker*m,double pos,unsigned x);
void dfs_order(struct conf*c,struct marker*m,double dist);
struct marker*other(struct edgelist*p,struct marker*m);
void append_edge(struct edgelist**list,struct edgelist*p);
void split_edges(struct earray*ea,struct map*mp);
int mcomp_func(const void*_m1, const void*_m2);
void split_markers(struct lg*p,struct map*mp);
void save_lg_markers(struct conf*c,const char*fname,struct lg*p);
void save_lg_map(const char*fname,struct lg*p);
void check_phase(struct conf*c,struct map*mp);
void distance_and_sort(struct conf*c,struct earray*ea);
void impute_missing(struct conf*c,struct lg*p,struct earray*ea);
void update_data(struct conf*c,unsigned nmark,struct marker**array);
double impute_est_rf(struct conf*c,struct marker*m1,struct marker*m2,unsigned x);
void append_knn(struct conf*c,struct missing*z,VARTYPE val,double rf);
void impute_alloc(struct conf*c,unsigned nmark,struct marker**array);
void calc_rflod_simple2(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,unsigned y,double*_lod,double*_rf);
void fix_marker_types(struct conf*c,struct lg*p,struct earray*ea,struct weights*w);
int ecomp_cxr_func(const void*_p1, const void*_p2);
void remove_redundant_markers(struct conf*c,struct lg*p,struct earray*e);
void identify_redundant_markers(struct conf*c,struct marker*m1,struct marker*m2,double rf,unsigned cxr_flag);
unsigned find_redundant(struct conf*c,VARTYPE*p1,VARTYPE*p2,double rf);
struct weights*decode_weights(char*weight_str);
#endif
