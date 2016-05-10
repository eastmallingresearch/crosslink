#!/usr/bin/Rscript

#
# create map using record method
#

library(onemap)

args = commandArgs(trailingOnly = TRUE)

inp = args[1]
out = args[2]
algorithm=args[3]

lod=1.0
maxrf=0.45

#cat(inp); cat("\n")
#cat(out)
cat("loading data...\n")
x = read.outcross("",inp)

cat("two point rf...\n")
x2pt = rf.2pts(x, LOD=lod, max.rf=maxrf)

xall = make.seq(x2pt, "all")

cat("make lgs...\n")
xlgs = group(xall, LOD=lod, max.rf=maxrf)

set.map.fun(type="haldane")

xlg1 <- make.seq(xlgs, 1)

if(algorithm == "om_record") {
    xout = record(xlg1)
} else if(algorithm == "om_seriation") {
    xout = seriation(xlg1)
} else if(algorithm == "om_rcd") {
    xout = rcd(xlg1)
} else if(algorithm == "om_ug") {
    xout = ug(xlg1)
}

write.map(xout,out)

#xrec

#cat("order.seq...\n")
#xord = order.seq(xlg1, n.init=5, THRES=3, touchdown=TRUE)

#ripple.seq(xord, ws=4, LOD=3)

#cat("exhaustive...\n")
#xcomp = compare(xlg1)

#the final map?
#xfinal = make.seq(xcomp,1,1)
