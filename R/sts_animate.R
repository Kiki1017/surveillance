################################################################################
### Part of the surveillance package, http://surveillance.r-forge.r-project.org
### Free software under the terms of the GNU General Public License, version 2,
### a copy of which is available at http://www.r-project.org/Licenses/.
###
### Animated map (and time series chart) of an sts-object (or matrix of counts)
###
### Copyright (C) 2013-2014 Sebastian Meyer
### $Revision: 1026 $
### $Date: 2014-09-23 20:43:58 +0200 (Tue, 23 Sep 2014) $
################################################################################


### Corresponding to the S3-generic function animate(),
### we define a method for the S4-class "sts" and omit the recommended
### setGeneric("animate"); setMethod("animate", "sts", animate.sts)
### [see Section "Methods for S3 Generic Functions" in help("Methods")]

animate.sts <- function (object, tps = NULL, cumulative = FALSE,
                         population = NULL, at = 10, ...,
                         timeplot = list(height = 0.3),
                         sleep = 0.5, verbose = interactive())
{
    if (dev.interactive())
        message("Advice: use facilities of the \"animation\" package, e.g.,\n",
                "        saveHTML() to view the animation in a web browser.")

    ## determine color breaks (checkat() is defined in stsplot_space.R)
    at <- checkat(at, data=.rangeOfDataToPlot(object, tps, cumulative, population))

    ## style of the additional temporal plot
    if (is.list(timeplot)) {
        timeplot <- modifyList(eval(formals()$timeplot), timeplot)
        timeplot_height <- timeplot$height
        timeplot$height <- NULL         # no parameter of stsplot_timesimple()
        stopifnot(timeplot_height > 0, timeplot_height < 1)
    }

    if (is.null(tps))
        tps <- seq_len(nrow(object))
    if (verbose)
        pb <- txtProgressBar(min=0, max=length(tps), initial=0, style=3)
    for(i in seq_along(tps)) {
        cti <- if (cumulative) seq_len(i) else i
        ls <- stsplot_space(object, tps=tps[cti], population=population,
                            at=at, ...)
        if (is.list(timeplot) && require("gridExtra")) {
            ## NOTE: unfortunately (R-exts, Section 1.1.3.1), only loading the
            ## namespace of package "gridExtra" would not be sufficient here;
            ## nothing would be plotted by grid.arrange() in that case ...
            lt <- do.call("stsplot_timeSimple", c(
                list(x=object, tps=tps, highlight=cti),
                timeplot))
            lt$aspect.fill <- FALSE
            lt$aspect.ratio <- timeplot_height * ls$aspect.ratio
            gridExtra::grid.arrange( # calls grid.draw()
                ls, lt, heights=c(1-timeplot_height, timeplot_height))
        } else print(ls)
        if (verbose) setTxtProgressBar(pb, i)
        if (dev.interactive()) Sys.sleep(sleep)
    }
    if (verbose) close(pb)
    invisible()
}


### additional time plot below the map

stsplot_timeSimple <- function (x, tps = NULL, highlight = integer(0),
                                inactive = list(col="gray", lwd=1),
                                active = list(col=1, lwd=4), ...)
{
    observed <- if (inherits(x, "sts")) observed(x) else x
    if (is.null(tps)) {
        tps <- seq_len(nrow(observed))
    } else {
        observed <- observed[tps,,drop=FALSE]
    }

    ## build highlight-specific style vectors (col, lwd, ...)
    stopifnot(is.list(inactive), is.list(active))
    stylepars <- intersect(names(inactive), names(active))
    styleargs <- sapply(stylepars, function (argname) {
        res <- rep.int(inactive[[argname]], length(tps))
        res[highlight] <- active[[argname]]
        res
    }, simplify=FALSE, USE.NAMES=TRUE)

    xyplot.args <- modifyList(c(list(x=rowSums(observed) ~ tps,
                                     type="h", ylab="", xlab=""),
                                styleargs),
                              list(...))
    do.call(lattice::xyplot, xyplot.args)
}


### determine data range for automatic color breaks 'at'

.rangeOfDataToPlot <- function (object, tps = NULL, cumulative = FALSE,
                                population = NULL)
{
    observed <- if (inherits(object, "sts")) observed(object) else object
    if (!is.null(tps)) {
        observed <- observed[tps,,drop=FALSE]
    }
    if (!is.null(population)) { # compute prevalence
        stopifnot(is.vector(population, mode="numeric"),
                  length(population) == ncol(object))
        observed <- observed / rep(population, each=nrow(observed))
    }
    range(if (cumulative) c(observed[1L,], colSums(observed)) else observed)
}