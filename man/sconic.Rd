\name{sconic}
\alias{sconic}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{Sconic
%%  ~~function to do ... ~~
}
\description{twice the radial height difference between a sphere and conic surface
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
sconic(D, rc, b = -1, lambda = 632.8, nmax = 6)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{D}{Diameter (mm)
%%     ~~Describe \code{D} here~~
}
  \item{rc}{Radius of curvature (mm)
%%     ~~Describe \code{rc} here~~
}
  \item{b}{conic constant
%%     ~~Describe \code{b} here~~
}
  \item{lambda}{source or test wavelength (nm)
%%     ~~Describe \code{lambda} here~~
}
  \item{nmax}{maximum polynomial order
%%     ~~Describe \code{nmax} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
Zernike polynomial coefficients
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
M.L. Peck
}
\note{
This estimates twice the radial distance between a sphere and conic surface with
same paraxial radius of curvature, and returns Zernike coefficients of polynomial expansion.
Intended for ``numerical nulling'' when testing an asphere at center of curvature, and
should be more accurate than the vertical height difference calculated by \code{\link{zconic}}
for that purpose.
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{\code{\link{zconic}}
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
  2.*zconic(1000,5000)
  sconic(1000,5000)
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{arith}% use one of  RShowDoc("KEYWORDS")

