#!/usr/bin/Rscript

#
# create map using record method
#

library(onemap)

args = commandArgs(trailingOnly = TRUE)

inp = args[1]
out = args[2]

lod=3.0
maxrf=0.4

#cat(inp); cat("\n")
#cat(out)
cat("loading data...\n")
x = read.outcross(".",inp)

cat("two point rf...\n")
x2pt = rf.2pts(x, LOD=lod, max.rf=maxrf)

xall = make.seq(x2pt, "all")

cat("make lgs...\n")
xlgs = group(xall, LOD=lod, max.rf=maxrf)

set.map.fun(type="haldane")

xlg1 <- make.seq(xlgs, 1)

#cat("seriation...\n")
#xser = seriation(xlg1)

#cat("rcd...\n")
#xrcd = rcd(xlg1)

#cat("record...\n")
#xrec = record(xlg1)


#xrec

cat("order.seq...\n")
xord = order.seq(xlg1, n.init=5, THRES=3, touchdown=TRUE)
xfinal <- make.seq(xord)
write.map(xfinal,out)

#ripple.seq(xord, ws=4, LOD=3)
#cat("ug...\n")
#xug  = ug(xlg1)

#cat("exhaustive...\n")
#xcomp = compare(xlg1)

#the final map?
#xfinal = make.seq(xcomp,1,1)
