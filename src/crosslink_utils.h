//Crosslink Copyright (C) 2016 NIAB EMR see included NOTICE file for details
#ifndef _RJV_CROSSLINK_UTILS_H_
#define _RJV_CROSSLINK_UTILS_H_

#include "crosslink_common.h"

struct marker* new_marker(struct conf*c,char*buff);
struct marker* create_marker_phased(struct conf*c,char*buff);
struct marker* create_marker_raw(struct conf*c,char*buff);
void load_raw(struct conf*c,const char*fname);
void load_phased_lg(struct conf*c,const char*fname,const char*lg);
void show_pearson_all(struct conf*c,struct map*mp);
double calc_pearson(unsigned n,struct marker**array);
int mpos_comp(const void*p1,const void*p2);
void set_true_positions(unsigned n,struct marker**array);
void random_bitstring(struct conf*c,BITTYPE*bits);
//void print_order(struct conf*c,struct marker**array,FILE*f);
void print_order(struct conf*c,unsigned nmarkers,struct marker**marray,FILE*f);
void utils_count_events(struct conf*c,VARTYPE*d1,VARTYPE*d2,unsigned*R,unsigned*N);
void print_map(unsigned n,struct marker**array,FILE*f,unsigned lg_numb,const char*lg_name);
int mpos_printorder(const void*p1,const void*p2);
double kosambi(double r);
double haldane(double r);
void randomise_order(unsigned n,struct marker**array);
void print_bits_inner(struct conf*c,struct marker**array);
void print_bits(struct conf*c,struct marker**array,unsigned pause);
void compress_to_bitstrings(struct conf*c,unsigned n,struct marker**array);
void to_bitstring(struct conf*c,VARTYPE*data,BITTYPE*bits,BITTYPE*mask);
void reset_r_matrix(struct conf*c);
void init_masks(struct conf*c);
void alloc_distance_cache(struct conf*c);
void alloc_hks(struct conf*c);
void assign_uids(unsigned n,struct marker**array);
void calc_RN_simple(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,unsigned*R,unsigned*N);
void indiv_map_positions(struct conf*c,struct marker**array,unsigned x);
void check_invert_paternal(unsigned n,struct marker**array);
void combine_maps(unsigned n,struct marker**array);
int mcomp_matpos(const void*_m1, const void*_m2);
int mcomp_combpos(const void*_m1, const void*_m2);
int mcomp_patpos(const void*_m1, const void*_m2);
void comb_map_positions(struct conf*c,unsigned n,struct marker**array,unsigned lg,unsigned flip_check);
void comb_map_positions2(struct conf*c,struct lg*p,unsigned flip_check);
void load_phased_all(struct conf*c,const char*fname,unsigned skip,unsigned total);
void calc_RN_simple2(struct conf*c,struct marker*m1,struct marker*m2,unsigned x,unsigned y,unsigned*R,unsigned*N);
struct marker* create_marker_phased_imputed(struct conf*c,char*buff);
void load_imputed_by_lg(struct conf*c,const char*fname);
double* find_maxlod(struct conf*c,double minlod);

void generic_load_all(struct conf*c,const char*fname,unsigned*nlgs,struct lg***lgs);
struct lg* generic_load_lg(struct conf*c,FILE*f,unsigned lgctr);
struct marker* generic_load_marker(struct conf*c,FILE*f,unsigned lgctr);
struct lg* generic_load_merged(struct conf*c,const char*fname,unsigned skip,unsigned total);
void generic_convert_to_unphased(struct conf*c,struct lg*p);
void generic_convert_to_phased(struct conf*c,struct lg*p);
void generic_convert_to_imputed(struct conf*c,struct lg*p);
void generic_apply_phasing(struct conf*c,struct lg*p);

struct lg* noheader_lg(struct conf*c,const char*fname);
struct marker*noheader_marker(struct conf*c,FILE*f);
struct lg* noheader_merged(struct conf*c,char*fnames,unsigned skip,unsigned total);

void check_no_missing(struct conf*c,char*fname,struct lg*p);
#endif
