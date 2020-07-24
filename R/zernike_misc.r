## Assorted routines for manipulation of
## Zernike polynomials, interferogram analysis,
## and other forms of optical testing

## Author: M.L. Peck (mlpeck54@gmail.com)
## Language: R (http://www.r-project.org/)
## Copyright (c) 2004-2019, M.L. Peck




## greyscale

grey256 <- gray(seq(0,1,length=256))
gray256 <- grey256

## A rainbow that may be better than R's rainbow() color palette

rygcb <- colorRampPalette(c("red", "yellow", "green", "cyan", "blue"), space = "Lab",
            interpolate="spline")
            
## Yet another rainbow made up of additive and subtractive primaries

rygcbm <- colorRampPalette(c("red", "yellow", "green", "cyan", "blue", "magenta"),
			space="Lab", interpolate="spline")

## a plot method for pupils

plot.pupil <- function(wf, cp=NULL, col=topo.colors(256), addContours=TRUE, 
                       cscale=FALSE, eqa=FALSE, zlim=NULL, ...) {
    nr <- nrow(wf)
    nc <- ncol(wf)
    if(is.null(zlim)) zlim <- range(wf, finite=TRUE)
    if(eqa) wfcdf <- ecdf(wf[!is.na(wf)])
    if (cscale) {
        mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
        on.exit(par(par.orig))
        w <- (3 + mar.orig[2]) * par("csi") * 2.54
        layout(matrix(c(2, 1), ncol = 2), widths = c(1, lcm(w)))
        par(las = 1)
        mar <- mar.orig
        mar[4] <- mar[2]
        mar[2] <- 1
        par(mar = mar)
        levels <- seq(zlim[1], zlim[2], length=length(col)+1)
        plot.new()
        plot.window(xlim=c(0,1),ylim=range(levels), xaxs="i", yaxs="i")
        if (eqa) {
            vcol <- col[round((length(col)-1)*wfcdf(seq(zlim[1],zlim[2],length=length(col)))+1)]
        } else vcol <- col
	rect(0, levels[-length(levels)], 1, levels[-1], col=vcol, density=NA)
        axis(4)
        box()
        mar <- mar.orig
        mar[4] <- 0
        par(mar = mar)
    }
    if (is.null(cp)) {
        axis1 <- 1:nr
        axis2 <- 1:nc
    } else {
        axis1 <- ((1:nr)-cp$xc)/cp$rx
        axis2 <- ((1:nc)-cp$yc)/cp$ry
    }
    if (eqa) {
        iwf <- wfcdf(wf[!is.na(wf)])
        iwfm <- wf
        iwfm[!is.na(iwfm)] <- iwf
        zlim <- wfcdf(zlim)
        col1 <- round((length(col)-1)*zlim[1]+1)
        col2 <- round((length(col)-1)*zlim[2]+1)
        image(axis1, axis2, iwfm, zlim=zlim, asp=1, col=col[col1:col2], 
              xlab="X", ylab="Y", useRaster=TRUE, ...)
    } else {
        image(axis1, axis2, wf, zlim=zlim, asp=1, col=col, 
                  xlab="X", ylab="Y", useRaster=TRUE, ...)
    }
    if (addContours) contour(axis1, axis2, wf, add=TRUE)
}

## comparison plot of n wavefront estimates

plotn <- function(...,
  labels=NULL, addContours=FALSE,
  wftype="net", col=rygcb(400), qt=c(.01, .99)) {
	fits <- list(...)
	nwf <- length(fits)
	wfget <- paste("wf",wftype,sep=".")
	wfi <- get(wfget, pos=fits[[1]])
	nr <- nrow(wfi)
	nc <- ncol(wfi)
	wfs <- array(0, dim=c(nr,nc,nwf))
	wfs[,,1] <- wfi
	for (i in 2:nwf) wfs[,,i] <- get(wfget,pos=fits[[i]])
	rm(fits)
	if(is.null(labels)) labels=1:nwf

	rdiff <- matrix(0,nwf*(nwf-1)/2,2)
	k <- 1
	for (i in 1:(nwf-1)) {
		for (j in (i+1):nwf) {
			rdiff[k,] <- quantile(wfs[,,i]-wfs[,,j], probs=qt, na.rm=TRUE)
			k <- k+1
		}
	}
	zlim <- range(rdiff)
	if (tolower(.Platform$OS.type)=="windows") windows(5*nwf, 5*nwf) else X11(5*nwf,5*nwf)
	par(mar=c(0,0,2,0))
	split.screen(figs=c(nwf,nwf))
	for (i in 1:nwf) {
	  screen(i)
	  wfi <- wfs[,,i]
	  class(wfi) <- "pupil"
	  plot(wfi, col=col, addContours=addContours, eqa=(wftype=="net"), axes=FALSE)
	  title(main=paste(labels[i],"rms=",format(pupilrms(wfi),digits=3)))
	}
	scr <- nwf+1
	for (row in 1:(nwf-1)) {
	  screen(scr)
	  plot(0:1,0:1,type="n",axes=FALSE)
	  text(0.5,0.5,labels[row])
	  scr <- scr+row
	  for (i in (row+1):nwf) {
		screen(scr)
		image(1:nr,1:nc,wfs[,,row]-wfs[,,i],col=grey256,asp=1,axes=FALSE,zlim=zlim,useRaster=TRUE)
		title(main=paste("rms diff =",format(pupilrms(wfs[,,row]-wfs[,,i]), digits=3)))
		scr <- scr+1
	  }
	}
	close.screen(all.screens=T)
}

## plot cross sections through a wavefront map

plotxs <- function(wf, cp, theta0=0, ylim=NULL, N=4, n=101,
	col0="black", col="gray", lty=2) {
  theta0 <- theta0*pi/180
  ixy <- seq(-1,1,length=n)
  theta <- (0:(N-1))*pi/N
  ix <- cp$rx*ixy
  iy <- cp$ry*ixy
  if (is.null(ylim)) ylim <- range(wf, na.rm=TRUE)
  plot(range(ixy),ylim, type="n", xlab="rho", ylab="Height")
  for (i in 1:N) {
	iix <- round(cp$xc+cos(theta[i])*ix)
	iiy <- round(cp$yc+sin(theta[i])*iy)
	points(ixy, diag(wf[iix,iiy]), type="l", col=col, lty=lty)
  }
  iix <- round(cp$xc+cos(theta0)*ix)
  iiy <- round(cp$yc+sin(theta0)*iy)
  points(ixy, diag(wf[iix,iiy]), type="l", col=col0, lty=lty)
}




## returns cosine and sine components of Bath astigmatism

##
# D = diameter
# rc = radius of curvature
# s = beam separation
# lambda = source wavelength
# phi = angle from horizontal (degrees)
##

astig.bath <- function(D, rc, s, lambda=1e-6, phi=0) {
    astig.tot <- D^2*s^2/(32*sqrt(6)*lambda*rc^3)
    astig.tot*c(cos(pi*phi/90),sin(pi*phi/90))
}



###########
## Various fun stuff
###########


## Star test simulator & support routines

## calculate phase values for wavefront at wavelength lambda
## replaces NA values with 0

wftophase <- function(X, lambda = 1) {
    phi <- exp(2i*pi*X/lambda)
    phi[is.na(phi)] <- 0
    phi
}

## puts matrix X into corner of npadded x npadded matrix
## padded with zeroes

padmatrix <- function(X, npad, fill=0) {
    nr <- nrow(X)
    nc <- ncol(X)
    xpad <- matrix(fill, npad, npad)
    xpad[1:nr,1:nc] <- X
    xpad
}


## extract a matrix from the center of a larger matrix


submatrix <- function(X,size=255) {
    nr <- nrow(X)
    X[((nr-size)/2+1):((nr+size)/2),((nr-size)/2+1):((nr+size)/2)]
}

## shuffle quadrants of a 2d fft around to display as an image


fftshift <- function(X) {
    nr <- nrow(X)
    XS <- matrix(0,nr,nr)
    XS[1:(nr/2),1:(nr/2)] <- X[(nr/2+1):nr,(nr/2+1):nr]
    XS[(nr/2+1):nr,(nr/2+1):nr] <- X[1:(nr/2),1:(nr/2)]
    XS[(nr/2+1):nr,1:(nr/2)] <- X[1:(nr/2),(nr/2+1):nr]
    XS[1:(nr/2),(nr/2+1):nr] <- X[(nr/2+1):nr,1:(nr/2)]
    XS
}

## computes & displays fraunhofer diffraction pattern
## & mtf for wavefront described in zernike coefficients zcoef

startest <- function(wf=NULL, zcoef=NULL, zlist=makezlist(), phi=0,
	lambda = 1, defocus=5,
	nrow = 255, ncol = nrow, cp = list(xc=128,yc=128,rx=127,ry=127,obstruct=0),
	obstruct=NULL, 
	npad = 4, 
	gamma=2, psfmag=2, displaymtf=TRUE, displaywf=FALSE) {

    if (tolower(.Platform$OS.type) == "windows") {
    windows(width=15, height=5) } else {
    x11(width=15,height=5)
    }
    screens<- split.screen(c(1,3))

    if (is.null(wf))
            wf <- pupil(zcoef=zcoef, zlist=zlist, phi=phi, nrow=nrow, ncol=ncol, cp=cp)
    else {
            nrow <- nrow(wf)
            ncol <- ncol(wf)
    }
    wf.df <- pupil(zcoef=c(0,0,1), zlist=makezlist(2,2), nrow=nrow, ncol=ncol, cp=cp)
    if (!is.null(obstruct)) wf[is.na(wf.df)] <- NA

    lx <- round(2*cp$rx)+1
    ly <- round(2*cp$ry)+1
    npad <- npad * .up2(lx,ly)

    phase <- wftophase(wf,lambda)
    up <- Mod(fft(padmatrix(phase,npad)))
    up <- up*up

    otf <- fft(up, inverse=TRUE)/npad^2
    otf <- otf[1:lx,1:ly]
    mtf <- Re(otf)
    mtf <- mtf/max(mtf)
    freqx <- seq(0,1,length=lx)
    freqy <- seq(0,1,length=ly)
    mtfideal <- 2/pi*(acos(freqx)-freqx*sqrt(1-freqx^2))

    nrpsf <- max(lx,ly)
    psf <- submatrix(fftshift(up),floor(nrpsf/psfmag))
    screen(screens[2])
    image(psf^(1/gamma),col=grey256,asp=1,bty='n', axes=FALSE, useRaster=TRUE)
    mtext("0")


    if (defocus >5) nrpsf <- 2*nrpsf
    if (defocus >15) nrpsf <- npad

    phase <- wftophase(wf - defocus/3.46*lambda*wf.df, lambda)
    up <- Mod(fft(padmatrix(phase,npad)))
    up <- up*up
    psf2 <- submatrix(fftshift(up),nrpsf)
    screen(screens[1])
    image(psf2^(1/gamma),col=grey256, asp=1,bty='n', axes=FALSE, useRaster=TRUE)
    mtext(-defocus)

    phase <- wftophase(wf + defocus/3.46*lambda*wf.df, lambda)
    up <- Mod(fft(padmatrix(phase,npad)))
    up <- up*up
    psf2 <- submatrix(fftshift(up),nrpsf)
    screen(screens[3])
    image(psf2^(1/gamma),col=grey256,asp=1,bty='n',axes=FALSE, useRaster=TRUE)
    mtext(defocus)
    close.screen(all.screens=TRUE)


    if (displaywf) {
            if (tolower(.Platform$OS.type) == "windows") windows() else x11()
            plot(wf/lambda)
    }

    if (displaymtf) {
            if (tolower(.Platform$OS.type) == "windows") windows() else x11()
            plot(freqx,mtf[1,],type="l",ylab="mtf",xlab="relative frequency")
            title(main='MTF vs. ideal')
            lines(freqy,mtf[,1])
            lines(freqx,mtfideal, lty=5)
            grid()
    }
    list(psf=psf, otf=otf, mtf=mtf)
}

## RGL animated 3D plot

## administrative stuff needed to make this a method for class "pupil"

wf3d <- function(wf, ...) UseMethod("wf3d", wf)

col3d <- function(wf, surf.col=topo.colors(256), zlim = NULL, eqa=FALSE) {
	if (is.null(zlim)) zlim <- range(wf, na.rm=TRUE)
    if (eqa) {
        wfcdf <- ecdf(wf[!is.na(wf)])
        iwf <- wfcdf(wf[!is.na(wf)])
        wf[!is.na(wf)] <- iwf
        zlim <- wfcdf(zlim)
    }
    surf.col[(length(surf.col)-1)*(wf-zlim[1])/(zlim[2]-zlim[1])+1]
}

wf3d.pupil <- function(wf, cp=NULL, zoom.wf=1, surf.col=topo.colors(256), bg.col="black",
                eqa=FALSE) {
    require(rgl)
    zlim <- range(wf, na.rm=TRUE)
    col <- col3d(wf, surf.col, zlim, eqa)
    if (is.null(cp)) {
        axis1 <- seq(-1, 1, length=nrow(wf))
        axis2 <- seq(-1, 1, length=ncol(wf))*(ncol(wf)/nrow(wf))
    } else {
        axis1 <- ((1:nrow(wf))-cp$xc)/cp$rx
        axis2 <- ((1:ncol(wf))-cp$yc)/cp$ry
    }

    rgl.bg(sphere=FALSE, fogtype="exp2", color=bg.col)
    rgl.surface(-axis1, axis2, wf*zoom.wf, color=col, shininess=100)
    rgl.lines(c(-1,-1.25)*max(axis1),c(0,0),c(0,0),color="red", lit=FALSE)
    rgl.lines(c(0,0),c(0,0),c(1,1.25)*max(axis2),color="red", lit=FALSE)
    rgl.texts(-1.3*max(axis1),0,0, "X", color="red")
    rgl.texts(0,0,1.3*max(axis2), "Y", color="red")
}

## Kolmogorov turbulence

turbwf <- function(friedratio=1, zlist=makezlist(2,40), reps=1) {
    require(mvtnorm)
    dimz <- length(zlist$n)
    cova <- matrix(0, nrow=dimz, ncol=dimz)
    c0 <- friedratio^(5/3)*gamma(14/3)*(4.8*gamma(1.2))^(5/6)*(gamma(11/6))^2/(2^(8/3)*pi)
    for (i in 1:dimz) {
        for (j in i:dimz) {
            if ((zlist$m[i] == zlist$m[j]) && (zlist$t[i] == zlist$t[j])) {
                n <- zlist$n[i]
                np <- zlist$n[j]
                cova[i,j] <- (-1)^((n+np-2*zlist$m[i])/2) * sqrt((n+1)*(np+1)) *
                                gamma((n+np-5/3)/2)/(gamma((np-n+17/3)/2)*gamma((n-np+17/3)/2)*
                                gamma((n+np+23/3)/2))
                cova[j,i] <- cova[i,j]
            }
        }
    }
    cova <- cova * c0/(4*pi^2)
    zcoef.turb <- rmvnorm(reps, mean=rep(0,dimz), sigma=cova)
    if (reps==1) zcoef.turb <- as.vector(zcoef.turb)
    list(zcoef.turb=zcoef.turb, V=cova)
}



## Foucault test simulator

foucogram <- function(wf, edgex = 0, phradius = 0, slit=FALSE, pad=4, gamma=1, 
                      map =FALSE, lev=0.5) {

    nr <- nrow(wf)
    nc <- ncol(wf)
    npad <- pad*nextn(max(nr,nc))
    phi<-padmatrix(wftophase(wf),npad)
    ca<-fftshift(fft(phi))
    u <- npad/2 + 1 + edgex
    ca[1:(u-phradius-1),]<-0
    ca[u,] <- .5*ca[u,]
    if (phradius>0) {
        if (slit) {
            for (i in 1:phradius) {
                f <- .5*(1+i/phradius)
                ca[(u+i),] <- f*ca[(u+i),]
                ca[(u-i),] <- (1-f)*ca[(u-i),]
            }
        } else {
            for (i in 1:phradius) {
                f <- .5 + i*sqrt(phradius^2-i^2)/(pi*phradius^2) + asin(i/phradius)/pi
                ca[(u+i),] <- f*ca[(u+i),]
                ca[(u-i),] <- (1-f)*ca[(u-i),]
            }
        }
    }
    ike <- Mod(fft(ca,inverse=T)[1:nr,1:nc])^2
    image(ike^(1/gamma),col=grey256,asp=nc/nr,axes=FALSE, useRaster=TRUE)
    if (map) {
        zmin <- floor(min(wf, na.rm=TRUE))
        zmax <- ceiling(max(wf, na.rm=TRUE))
        contour(wf,add=TRUE,levels=seq(zmin,zmax,by=lev),
                axes=FALSE,frame.plot=FALSE,col="red")
    }
    ike/max(ike)
}

## Synthetic interferogram

synth.interferogram <- function(wf=NULL, zcoef=NULL, zlist=NULL, 
                                nr=nrow(wf), nc=ncol(wf), cp=NULL, 
                                phi=0, addzc=rep(0,4), fringescale=1, 
                                plots=TRUE) {
    addzl <- makezlist(2,2)
    if (is.null(wf)) {
        if (is.null(cp)) {
            wf <- pupil(zcoef=zcoef, zlist=zlist, phi=phi)+
                        pupil(zcoef=addzc[-1], zlist=addzl, piston=addzc[1])
            nr <- nrow(wf)
            nc <- ncol(wf)
        } else {
            wf <- pupil(zcoef=zcoef, zlist=zlist, phi=phi, nrow=nr, ncol=nc, cp=cp) +
                  pupil(zcoef=addzc[-1], zlist=addzl, piston=addzc[1], 
                        nrow=nr, ncol=nc, cp=cp)
        }
    } else {
        if (is.null(cp)) {
            wf <- wf + pupil(zcoef=addzc[-1], zlist=addzl, piston=addzc[1], nrow=nr, ncol=nc)
        } else {
            wf <- wf + pupil(zcoef=addzc[-1], zlist=addzl, piston=addzc[1], 
                             nrow=nr, ncol=nc, cp=cp)
        }
    }
    igram <- cos(2*pi*wf/fringescale)
    igram[is.na(igram)] <- 0
    class(igram) <- "pupil"
    if (plots) plot(igram, col=grey256, addContours=FALSE)
    igram
}


#########
## general utilities
#########

## crop an array

crop <- function(img, cp, npad=20) {
    nr <- dim(img)[1]
    nc <- dim(img)[2]
    xmin <- max(1, round(cp$xc-cp$rx-npad))
    xmax <- min(nr, round(cp$xc+cp$rx+npad))
    ymin <- max(1, round(cp$yc-cp$ry-npad))
    ymax <- min(nc, round(cp$yc+cp$rx+npad))
    cp.new <- cp
    cp.new$xc <- cp$xc-xmin+1
    cp.new$yc <- cp$yc-ymin+1
    if (length(dim(img)) > 2) img <- img[xmin:xmax,ymin:ymax,]
    else img <- img[xmin:xmax,ymin:ymax]
    list(im=img, cp=cp.new)
}

## general purpose 2D convolution using FFT's.

## kern is the convolution kernel

convolve2d <- function(im, kern) {
	nr <- nrow(im)
	nc <- ncol(im)
	nrp <- nr + nrow(kern) - 1
	ncp <- nc + ncol(kern) - 1
	xs <- nrow(kern) %/% 2 + nrow(kern) %% 2
	ys <- ncol(kern) %/% 2 + ncol(kern) %% 2
	npad <- nextn(max(nrp, ncp))
	kern <- padmatrix(kern, npad=npad)
	im <- padmatrix(im, npad=npad)
	im.f <- Re(fft(fft(kern)*fft(im), inv=T))
	im.f <- im.f[xs:(nr+xs-1),ys:(nc+ys-1)]/(npad^2)
	return(im.f)
}


## Gaussian blur. fw is the standard deviation
## of the gaussian convolution kernel, in pixels.

gblur <- function(X, fw = 0, details=FALSE) {
  if (fw == 0) return(X)
  XP <- X
  XP[is.na(XP)] <- 0
  nr <- nrow(X)
  nc <- ncol(X)
  ksize <- max(ceiling(4 * fw), 3)
  if ((ksize %% 2) == 0) ksize <- ksize+1
  xc <- (ksize %/% 2) + 1
  xs <- ((1:ksize)-xc)/fw
  gkern <- outer(xs, xs, function(x,y) (x^2+y^2))
  gkern <- exp(-gkern/2)
  gkern <- round(gkern/min(gkern))
  npad <- nextn(max(nr,nc)+ksize-1)
  XP <- padmatrix(XP, npad)
  kernp <- padmatrix(gkern, npad)
  XP <- Re(fft(fft(XP)*fft(kernp), inv=TRUE))/(npad^2)/sum(gkern)
  XP <- XP[xc:(nr+xc-1), xc:(nc+xc-1)]
  XP[is.na(X)] <- NA
  if (details) 
	  return(list(gkern=gkern, X=XP))
  else return(XP)
}
 


## Plot a complex matrix. 
## Maybe make cmat a class, so this becomes default plot routine?

plot.cmat <- function(X, fn="Mod", col=grey256, cp=NULL, zoom=1, gamma=1, ...) {
	  ## define some possibly useful functions. Note Mod2 produces power spectrum
	  
	logMod <- function(X) log(1+Mod(X))
	Mod2 <- function(X) Mod(X)^2
	logMod2 <- function(X) log(Mod2(X))
	nr <- nrow(X)
	nc <- ncol(X)
	xs <- seq(-nr/2,nr/2-1,length=nr)
	ys <- seq(-nc/2,nc/2-1,length=nc)
	if (!is.null(cp)) {
		xs <- (cp$rx/nr)*xs
		ys <- (cp$ry/nc)*ys
	}
	xsub <- max(1, floor(1+nr/2*(1-1/zoom))) : min(nr, ceiling(nr/2*(1+1/zoom)))
	ysub <- max(1, floor(1+nc/2*(1-1/zoom))) : min(nc, ceiling(nc/2*(1+1/zoom)))
	image(xs[xsub], ys[ysub], (eval(call(fn, X))[xsub,ysub])^(1/gamma), 
	  col=col, asp=1, xlab="k_x", ylab="k_y", useRaster=TRUE, ...)
}


pick.sidelobe <- function(imagedata, logm=FALSE, gamma=3) {
	imagedata <- imagedata - mean(imagedata)
	npad <- nextn(max(nrow(imagedata), ncol(imagedata)))
	im <- padmatrix(imagedata, npad=npad, fill=0)
	if (logm) fn <- "logMod2" else fn <- "Mod"
	im.fft <- fftshift(fft(im))
	plot.cmat(im.fft, fn=fn, gamma=gamma)
	cat("Click on the desired sidelobe peak\n")
	peak <- locator(n=1, type="p", col="red")
	cat("Click on background filter size\n")
	edge <- locator(n=1, type="n")
	hw <- round(sqrt((edge$x)^2+(edge$y)^2))
	symbols(0, 0, circles=hw, inches=FALSE, add=TRUE, fg="red")
	return(list(sl=c(round(peak$x), round(peak$y)), filter=hw))
}


## simple utility returns Euclidean length of a vector

hypot <- function(x) sqrt(crossprod(x))

## Zernike moments

zmoments <- function(zcoef, maxorder=14) {
    zcoef <- zcoef[-(1:3)]
    zlist <- makezlist(4, maxorder)
    nz <- length(zlist$n)
    sumstats <- NULL
    i <- 1
    repeat {
        if (i > nz) break
            if (zlist$m[i] == 0) {
                sumstats <- rbind(sumstats, c(zlist$n[i], zlist$m[i], zcoef[i]))
                i <- i+1
            }
            else {
                sumstats <- rbind(sumstats, c(zlist$n[i], zlist$m[i], hypot(zcoef[i:(i+1)])))
                i <- i+2
            }
    }
    sumstats <- data.frame(sumstats)
    names(sumstats) <- c("n", "m", "value")
    return(sumstats)
}

## these two functions provide rudimentary project management. The first adds
## Zernike coefficients and rotation angles from one or more fits to a matrix.
## The second separates polished in from instrumental aberrations (if possible)

addfit <- function(..., th=0, zcm=NULL, theta=numeric(0)) {
    fits <- list(...)
    nt <- length(fits)
    if (length(th)==1 && nt>1) th=rep(th, nt)
    theta <- c(theta, th*pi/180)
    nz <- length(fits[[1]]$zcoef.net)
    for (i in 1:nt) {
        zcm <- cbind(zcm, fits[[i]]$zcoef.net[4:nz])
    }
    list(zcm=zcm, theta=theta)
}

separate.wf <- function(zcm, theta, maxorder=14) {
    
    nt <- length(theta)
    zlist <- makezlist(4, maxorder)
    nz <- length(zlist$n)
    zcb <- matrix(0, nz, 4)
    sumstats <- NULL
    cx <- c(rep(1,nt),rep(0,nt))
    cy <- c(rep(0,nt),rep(1,nt))
    i <- 1
    repeat {
        if (i > nz) break
        if (zlist$m[i] == 0) {
            zcb[i,1] <- mean(zcm[i,])
            zcb[i,3] <- sd(zcm[i,])/sqrt(nt)
            sumstats <- rbind(sumstats, c(zlist$n[i], zlist$m[i], zcb[i,1],
                                NA, zcb[i, 3], rep(NA, 4)))
            i <- i+1
        } else {
            y <- c(zcm[i,],zcm[i+1,])
            rx <- c(cos(zlist$m[i]*theta),sin(zlist$m[i]*theta))
            ry <- c(-sin(zlist$m[i]*theta),cos(zlist$m[i]*theta))
            lsm <- lm(y ~ -1+rx+ry+cx+cy)
            cc <- coef(summary(lsm))[,1:2]
            zcb[i:(i+1),1] <- cc[1:2,1]
            zcb[i:(i+1),3] <- cc[1:2,2]
            if (nrow(cc)==4) {
                zcb[i:(i+1),2] <- cc[3:4,1]
                zcb[i:(i+1),4] <- cc[3:4,2]
            }
            lsm <- summary(lsm)
            sumstats <- rbind(sumstats,c(zlist$n[i],zlist$m[i],
                                hypot(zcb[i:(i+1),1]), hypot(zcb[i:(i+1),2]),
                                lsm$sigma, lsm$r.squared,lsm$fstatistic))
            i <- i+2
        }
    }
    zcb[is.na(zcb)] <- 0
    colnames(zcb) <- c("zc_mirror", "zc_inst", "se_zc_mirror", "se_zc_inst")
    colnames(sumstats)[1:7] <- c("n","m","rms_mirror", "rms_inst", "sigma","R2", "F")
    wf.mirror <- pupil.arb(zcoef=zcb[,1],zlist=zlist)
    wf.inst <- pupil.arb(zcoef=zcb[,2], zlist=zlist)
    list(zcb=data.frame(zcb),sumstats=data.frame(sumstats),
        wf.mirror=wf.mirror, wf.inst=wf.inst)
}
