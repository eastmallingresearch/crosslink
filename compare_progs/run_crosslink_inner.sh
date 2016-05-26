#$ -S /bin/bash
#$ -l h_vmem=0.5G
#$ -l mem_free=0.5G
#$ -l virtual_free=0.5G
#$ -l h_rt=999:00:00

#Crosslink, Copyright (C) 2016  NIAB EMR

#
# run one test to optmise crosslg marker detection parameters
#

set -eu

if [ "$1" == "cl_approx" ]
then
    echo grouping...
    crosslink_group\
            --seed=0\
            --inp=${FILEBASE}.loc\
            --log=group.log\
            --outbase=group\
            --mapbase=group\
            --min_lod=1.0\
            --ignore_cxr=1\
            --knn=3

    mv group000.map out000.map

elif [ "$1" == "cl_full" ]
then
    echo grouping...
    crosslink_group\
            --seed=0\
            --inp=${FILEBASE}.loc\
            --log=group.log\
            --outbase=group\
            --min_lod=1.0\
            --ignore_cxr=1\
            --knn=3

    echo mapping...
    crosslink_map\
        --seed=0\
        --inp=group000.loc\
        --out=out000.loc\
        --map=out000.map\
        --log=map.log\
        --randomise_order=0\
        --ga_skip_order1=1\
        --ga_gibbs_cycles=5\
        --ga_iters=200000\
        --ga_use_mst=3\
        --ga_minlod=10\
        --ga_mst_nonhk=0\
        --ga_optimise_meth=0\
        --ga_prob_hop=0.333\
        --ga_max_hop=0.0\
        --ga_prob_move=0.333\
        --ga_max_mvseg=1.0\
        --ga_max_mvdist=1.0\
        --ga_prob_inv=0.5\
        --ga_max_seg=1.0\
        --gibbs_samples=300\
        --gibbs_burnin=10\
        --gibbs_period=1\
        --gibbs_prob_sequential=0.0\
        --gibbs_prob_unidir=1.0\
        --gibbs_min_prob_1=0.1\
        --gibbs_min_prob_2=0.0\
        --gibbs_twopt_1=0.5\
        --gibbs_twopt_2=0.0

elif [ "$1" == "cl_global" ]
then
    echo grouping...
    crosslink_group\
            --seed=0\
            --inp=${FILEBASE}.loc\
            --log=group.log\
            --outbase=group\
            --min_lod=1.0\
            --ignore_cxr=1\
            --knn=3

    echo mapping...
    crosslink_map\
        --seed=0\
        --inp=group000.loc\
        --out=out000.loc\
        --map=out000.map\
        --log=map.log\
        --randomise_order=0\
        --ga_skip_order1=1\
        --ga_gibbs_cycles=5\
        --ga_iters=200000\
        --ga_use_mst=3\
        --ga_minlod=10\
        --ga_mst_nonhk=0\
        --ga_optimise_meth=2\
        --ga_prob_hop=0.333\
        --ga_max_hop=0.0\
        --ga_prob_move=0.333\
        --ga_max_mvseg=1.0\
        --ga_max_mvdist=1.0\
        --ga_prob_inv=0.5\
        --ga_max_seg=1.0\
        --gibbs_samples=300\
        --gibbs_burnin=10\
        --gibbs_period=1\
        --gibbs_prob_sequential=0.0\
        --gibbs_prob_unidir=1.0\
        --gibbs_min_prob_1=0.1\
        --gibbs_min_prob_2=0.0\
        --gibbs_twopt_1=0.5\
        --gibbs_twopt_2=0.0

elif [ "$1" == "cl_refine" ]
then
    echo grouping...
    crosslink_group\
            --seed=0\
            --inp=${FILEBASE}.loc\
            --log=group.log\
            --outbase=group\
            --min_lod=1.0\
            --ignore_cxr=1\
            --knn=3

    echo mapping...
    crosslink_map\
        --seed=0\
        --inp=group000.loc\
        --out=out000.loc\
        --map=out000.map\
        --log=map.log\
        --randomise_order=0\
        --ga_skip_order1=1\
        --ga_gibbs_cycles=5\
        --ga_iters=200000\
        --ga_use_mst=3\
        --ga_minlod=10\
        --ga_mst_nonhk=0\
        --ga_optimise_meth=0\
        --ga_prob_hop=0.333\
        --ga_max_hop=0.0\
        --ga_prob_move=0.333\
        --ga_max_mvseg=1.0\
        --ga_max_mvdist=1.0\
        --ga_prob_inv=0.5\
        --ga_max_seg=1.0\
        --gibbs_samples=300\
        --gibbs_burnin=10\
        --gibbs_period=1\
        --gibbs_prob_sequential=0.0\
        --gibbs_prob_unidir=1.0\
        --gibbs_min_prob_1=0.1\
        --gibbs_min_prob_2=0.0\
        --gibbs_twopt_1=0.5\
        --gibbs_twopt_2=0.0

    echo refining...
    mkdir grps
    mv out000.loc grps/out000.loc
    cl_refine_order.sh   grps   refgrps   20   1   ../conf/refine.000
    crosslink_pos --inp=refgrps/out000.loc --out=out000.map
else
    echo "unknown option" $1
    exit 1
fi
