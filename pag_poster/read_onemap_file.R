#read in a onemap file using a non-geological time-scale
#
#file(description = "", open = "", blocking = TRUE, encoding = getOption("encoding"), raw = FALSE)
#

read_onemap_file = function(fname)
{
    f = file(description=fname, open="r")

    header = readLines(con=f, n=1)
    tok = strsplit(header," ")[[1]]
    n.ind = as.numeric(tok[1])
    n.mar = as.numeric(tok[2])
    
    marnames = rep("", n.mar)
    geno = matrix(0, nrow=n.ind, ncol=n.mar)
    segr.type = character(n.mar)
    
    for (i in 1:n.mar)
    {
        nxtline = readLines(con=f, n=1)
        tok = strsplit(nxtline," ")[[1]]

        marnames[i] = substring(tok[1], 2)
        segr.type[i] = tok[2]
        
        calls = strsplit(tok[3], ",")[[1]]
        geno[1:n.ind,i] = as.character(calls)
    }
    
    close(f)
    
    colnames(geno) = marnames
    geno[!is.na(geno) & geno == "-"] <- NA
    temp.data <- codif.data(geno, segr.type)
    geno <- temp.data[[1]]
    segr.type.num <- temp.data[[2]]
    rm(temp.data)
    cat(" --Read the following data:\n")
    cat("\tNumber of individuals: ", n.ind, "\n")
    cat("\tNumber of markers:     ", n.mar, "\n")
    
    structure(list(geno = geno, n.ind = n.ind, n.mar = n.mar, 
        segr.type = segr.type, segr.type.num = segr.type.num, 
        input = file), class = "outcross")
}
