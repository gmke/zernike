//
//	Copyright (C) 2021 Michael Peck <mpeck1 -at- ix.netcom.com>
//
//	License: MIT <https://opensource.org/licenses/MIT>
//


# include <Rcpp.h>
using namespace Rcpp;

/*****************
 * 
 * Convert a matrix of Zernike polynomial values
 * from unit scaled to unit variance (orthonormal scaling).
 * Columns must be in ISO/ANSI sequence. 
 * Only check performed is on number of columns.
 * 
*****************/


//' Normalize matrix of Zernike polynomial values.
//'
//' Convert a matrix of Zernike polynomial values from
//' unit scaled to unit variance aka orthonormal form.
//'
//' @param uzpm matrix of Zernike polynomial values
//' @param maxorder the maximum radial order.
//'
//' @return matrix in orthonormal form.
//'
//' @details
//'  This is intended only for ISO/ANSI ordered matrices. The
//'  only check performed is that the number of columns in the
//'  matrix matches the expected number given by the argument
//'  `maxorder`.
//'  This is called by [gradzpm_cart()] and [zpm_cart()]
//'  if `unit_variance` is set to `true` in the respective
//'  function calls.
//' @md
// [[Rcpp::export]]
NumericMatrix norm_zpm(NumericMatrix& uzpm, const int& maxorder = 12) {
  int ncol = uzpm.cols();
  int n, m, mp, j=0;
  double zmult;
  
  if (ncol != (maxorder+1)*(maxorder+2)/2) stop("Matrix is wrong size for entered order");
  
  for (n=0; n<=maxorder; n++) {
    for (m=0; m<=n; m++) {
      mp = n - 2*m;
      zmult = std::sqrt(n+1.0);
      if (mp != 0) {
        zmult *= sqrt(2.0);
      }
      uzpm(_, j) = zmult * uzpm(_, j);
      ++j;
    }
  }
  return uzpm;
}
      
  
  
/********************
 Fill matrixes with:
 unit scaled Zernikes in cartesian coordinates
 x and y directional derivatives
 
 Note: This returns ZP values in ISO?ANSI ordering with sine terms on
       the "left" side of the pyramid.
 
 Source:
 Anderson, T.B. (2018) Optics Express 26, #5, 18878
 URL: https://doi.org/10.1364/OE.26.018878 (open access)
********************/


//' Zernike polynomials and cartesian gradients
//'
//' Calculate Zernike polynomial values and Cartesian gradients in
//' ISO/ANSI sequence for a set of Cartesian coordinates.
//'
//' @param x a vector of x coordinates for points on a unit disk.
//' @param y a vector of y coordinates.
//' @param maxorder the maximum radial polynomial order (defaults to 12).
//' @param unit_variance logical: return with orthonormal scaling? (default `false`)
//' @param return_zpm logical: return Zernike polynomial matrix? (default `true`)
//'
//' @return a named list with the matrices `zm` (optional but returned by default), `dzdx`, `dzdy`.
//'
//' @references
//'   Anderson, T.B. (2018) Optics Express 26, #5, 18878
//'   <https://doi.org/10.1364/OE.26.018878> (open access)
//'
//' @details
//'  Uses the recurrence relations in the above publication to calculate Zernike
//'  polynomial values and their directional derivatives in Cartesian coordinates. These are
//'  known to be both efficient and numerically stable.
//'
//'  Columns are in ISO/ANSI sequence: for each radial order n >= 0 the azimuthal orders m are sequenced
//'  m = {-n, -(n-2), ..., (n-2), n}, with sine components for negative m and cosine for positive m. Note this
//'  is the opposite ordering from the extended Fringe set and the ordering of aberrations is quite different. 
//'  For example the two components of trefoil are in the 7th and 10th column while coma is in
//'  columns 8 and 9 (or 7 and 8 with 0-indexing). Note also that except for tilt and coma-like aberrations
//'  (m=1) non-axisymmetric aberrations will be separated.
//'
//'  All three matrices will have the same dimensions on return. Columns 0 and 1 of `dzdx` will be all 0,
//'  while columns 0 and 3 of `dzdy` are 0.
//'
//' @seealso [zpm()] uses the same recurrence relations for polar coordinates and extended
//'  Fringe set ordering, which is the more common indexing scheme for optical design/testing
//'  software.
//' @seealso [zpm_cart()] calculates and returns the Zernike polynomial values only.
//'
//' @examples
//'  rho <- seq(0.2, 1., length=5)
//'  theta <- seq(0, 1.6*pi, length=5)
//'  rt <- expand.grid(theta, rho)
//'  x <- c(0, rt[,2]*cos(rt[,1]))
//'  y <- c(0, rt[,2]*sin(rt[,1]))
//'  gzpm <- gradzpm_cart(x, y)
//'
//' @md
// [[Rcpp::export]]
List gradzpm_cart(const NumericVector& x, const NumericVector& y, const int& maxorder = 12, 
             const bool& unit_variance = false, const bool& return_zpm = true) {
  
  int n, m;
  int ncol = (maxorder+1)*(maxorder+2)/2;
  unsigned int nrow = x.size();
  int j;
  bool n_even;
  NumericMatrix zm(nrow, ncol), dzdx(nrow, ncol), dzdy(nrow, ncol);
  
  //do some rudimentary error checking
  
  if (x.size() != y.size()) stop("Numeric vectors must be same length");
  if (maxorder < 1) stop("maxorder must be >= 1");
  
  // good enough
  
  
  // starting values for recursions
  
  zm(_, 0) = rep(1.0, nrow);
  zm(_, 1) = y;
  zm(_, 2) = x;
  
  dzdx(_, 0) = rep(0.0, nrow);
  dzdx(_, 1) = rep(0.0, nrow);
  dzdx(_, 2) = rep(1.0, nrow);
  
  dzdy(_, 0) = rep(0.0, nrow);
  dzdy(_, 1) = rep(1.0, nrow);
  dzdy(_, 2) = rep(0.0, nrow);
  
  j = 3;
  n_even = true;
  for (n=2; n <= maxorder; n++) {
    
    // fill in  m=0
    m=0;
    zm(_, j) = x*zm(_, j-n) + y*zm(_, j-1);
    dzdx(_, j) = (double) n * zm(_, j-n);
    dzdy(_, j) = (double) n * zm(_, j-1);
    ++j;
    
    for (m=1; m < n/2; m++) {
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      dzdx(_, j) = (double) n*zm(_, j-n) + (double) n*zm(_, j-n-1) + dzdx(_, j-2*n);
      dzdy(_, j) = (double) n*zm(_, j-2*m-1) - (double) n*zm(_, j-2*m) + dzdy(_, j-2*n);
      ++j;
    }
    if (n_even) {
      zm(_, j) = 2.*x*zm(_, j-n) + 2.*y*zm(_, j-n-1) - zm(_, j-2*n);
      dzdx(_, j) = 2.*(double) n*zm(_, j-n) + dzdx(_, j-2*n);
      dzdy(_, j) = 2.*(double) n*zm(_, j-2*m-1) + dzdy(_, j-2*n);
      ++m;
      ++j;
    } else {
      zm(_, j) = y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      dzdx(_, j) = (double) n*zm(_, j-n-1) + dzdx(_, j-2*n);
      dzdy(_, j) = (double) n*(zm(_, j-2*m-1) - zm(_, j-2*m)) + dzdy(_, j-2*n);
      ++m;
      ++j;
      
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - zm(_, j-2*n);
      dzdx(_, j) = (double) n*(zm(_, j-n) + zm(_, j-n-1)) + dzdx(_, j-2*n);
      dzdy(_, j) = (double) n*zm(_, j-2*m-1) + dzdy(_, j-2*n);
      ++m;
      ++j;
    }
    for (m=m; m<n; m++) {
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      dzdx(_, j) = (double) n*zm(_, j-n) + (double) n*zm(_, j-n-1) + dzdx(_, j-2*n);
      dzdy(_, j) = (double) n*zm(_, j-2*m-1) - (double) n*zm(_, j-2*m) + dzdy(_, j-2*n);
      ++j;
    }
    
    // m = n
    
    zm(_, j) = x*zm(_, j-n-1) - y*zm(_, j-2*n);
    dzdx(_, j) = (double) n * zm(_, j-n-1);
    dzdy(_, j) = (double) -n * zm(_, j-2*n);
    ++j;
    
    n_even = !n_even;
  }
  
  //orthonormalize if requested
    
  if (unit_variance) {
    zm = norm_zpm(zm, maxorder);
    dzdx = norm_zpm(dzdx, maxorder);
    dzdy = norm_zpm(dzdy, maxorder);
  }
  
  if (return_zpm) {
    return List::create(Named("zm") = zm, Named("dzdx") = dzdx, Named("dzdy") = dzdy);
  } else {
    return List::create(Named("dzdx") = dzdx, Named("dzdy") = dzdy);
  }
}

/*****************
 * Fill matrix of Zernike polynomial values in cartesian coordinates.
 * 
 * This is just the above code with all references to directional
 * derivatives removed.
*****************/


//' Zernike polynomials
//'
//' Calculate Zernike polynomial values in
//' ISO/ANSI sequence for a set of Cartesian coordinates.
//'
//' @param x a vector of x coordinates for points on a unit disk.
//' @param y a vector of y coordinates.
//' @param maxorder the maximum radial polynomial order (defaults to 12).
//' @param unit_variance logical: return with orthonormal scaling? (default `false`)
//'
//' @return a matrix of Zernike polynomial values evaluated at the input
//'  Cartesian coordinates and all radial and azimuthal orders from
//'  0 through `maxorder`.
//'
//' @details This is the same algorithm and essentially the same code as [gradzpm_cart()]
//'  except directional derivatives aren't calculated.
//' @md
// [[Rcpp::export]]
NumericMatrix zpm_cart(const NumericVector& x, const NumericVector& y, const int& maxorder = 12, 
                       const bool& unit_variance = true) {
  
  int n, m;
  int ncol = (maxorder+1)*(maxorder+2)/2;
  unsigned int nrow = x.size();
  int j;
  bool n_even;
  NumericMatrix zm(nrow, ncol);
  CharacterVector cnames(ncol);
  
  //do some rudimentary error checking
  
  if (x.size() != y.size()) stop("Numeric vectors must be same length");
  if (maxorder < 1) stop("maxorder must be >= 1");
  
  // good enough
  
  
  // starting values for recursions
  
  zm(_, 0) = rep(1.0, nrow);
  zm(_, 1) = y;
  zm(_, 2) = x;
  
  j = 3;
  n_even = true;
  for (n=2; n <= maxorder; n++) {
    
    // fill in  m=0
    m=0;
    zm(_, j) = x*zm(_, j-n) + y*zm(_, j-1);
    ++j;
    
    for (m=1; m < n/2; m++) {
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      ++j;
    }
    if (n_even) {
      zm(_, j) = 2.*x*zm(_, j-n) + 2.*y*zm(_, j-n-1) - zm(_, j-2*n);
      ++m;
      ++j;
    } else {
      zm(_, j) = y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      ++m;
      ++j;
      
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - zm(_, j-2*n);
      ++m;
      ++j;
    }
    for (m=m; m<n; m++) {
      zm(_, j) = x*zm(_, j-n) + y*zm(_, j-2*m-1) + x*zm(_, j-n-1) - y*zm(_, j-2*m) - zm(_, j-2*n);
      ++j;
    }
    
    // m = n
    
    zm(_, j) = x*zm(_, j-n-1) - y*zm(_, j-2*n);
    ++j;
    
    n_even = !n_even;
  }
  
  //orthonormalize if requested
    
  if (unit_variance) {
    zm = norm_zpm(zm, maxorder);
  }
  
  // add column names
  
    for (j=0; j<ncol; j++) {
    cnames(j) = "Z" + std::to_string(j);
  }
  colnames(zm) = cnames;

  return zm;
}

