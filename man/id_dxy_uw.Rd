% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{id_dxy_uw}
\alias{id_dxy_uw}
\title{Compiled code via Rcpp for Itoh's method of phase unwrapping}
\usage{
id_dxy_uw(nr, nc, phase, mask, dx, dy, uw)
}
\arguments{
\item{nr}{number of rows in phase matrix}

\item{nc}{number of columns in phase matrix}

\item{phase}{phase matrix converted to vector}

\item{mask}{matrix of mask values converted to vector}

\item{dx}{wrapped phase differences in x direction}

\item{dy}{wrapped phase differences in y direction}
}
\value{
a vector with the unwrapped phase
}
\description{
Called by \code{\link[=brcutpuw]{brcutpuw()}} for fast phase unwrapping
}
\details{
This is called by \code{\link[=brcutpuw]{brcutpuw()}} through \code{\link[=idiffpuw]{idiffpuw()}}
but is also user callable.
Wrapped phase values and differences are divided by \code{2*pi} before input
making the input values in the range [-1/2, 1/2).
In \code{\link[=brcutpuw]{brcutpuw()}} the mask indicates areas outside the interferogram area
and lines of branch cuts
}
\seealso{
\code{\link[=brcutpuw]{brcutpuw()}}, \code{\link[=idiffpuw]{idiffpuw()}}
}
\author{
M.L. Peck (mlpeck54 -at- gmail.com)
}
