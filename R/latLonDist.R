##
## translated from: http://www.movable-type.co.uk/scripts/latlong-vincenty.html
##
## /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
## /* Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2012             */
## /*                                                                                                */
## /* from: Vincenty inverse formula - T Vincenty, "Direct and Inverse Solutions of Geodesics on the */
## /*       Ellipsoid with application of nested equations", Survey Review, vol XXII no 176, 1975    */
## /*       http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf                                             */
## /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

## /**
##  * Calculates geodetic distance between two points specified by latitude/longitude using 
##  * Vincenty inverse formula for ellipsoids
##  *
##  * @param   {Number} lat1, lon1: first point in decimal degrees
##  * @param   {Number} lat2, lon2: second point in decimal degrees
##  * @returns (Number} distance in metres between points
##  */

latLonDist = function(lat1, lon1, lat2, lon2) {
  a = 6378137
  b = 6356752.314245
  f = 1/298.257223563  ## WGS-84 ellipsoid params
  
  llmat = cbind(lat1, lon1, lat2, lon2) ## recycles coordinates to match
  
  s = rep(-1, nrow(llmat)) ## return values; -1 means not yet computed
  for (i in 1:nrow(llmat)) {  ## calculate distance between i'th pair of points
    if (!all(is.finite(llmat[i,]))) {
      s[i] = NA
      next
    }
    
    L = rad(llmat[i, 4]-llmat[i, 2])
    U1 = atan((1-f) * tan(rad(llmat[i, 1])))
    U2 = atan((1-f) * tan(rad(llmat[i, 3])))
    sinU1 = sin(U1)
    cosU1 = cos(U1)
    sinU2 = sin(U2)
    cosU2 = cos(U2)
    lambda = L
    iterLimit = 100
    repeat {
      sinLambda = sin(lambda)
      cosLambda = cos(lambda)
      sinSigma = sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + 
                        (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda))
      if (abs(sinSigma) < 1e-10) {
        s[i] = 0 ## co-incident points
        break
      }
      cosSigma = sinU1*sinU2 + cosU1*cosU2*cosLambda
      sigma = atan2(sinSigma, cosSigma)
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
      cosSqAlpha = 1 - sinAlpha*sinAlpha
      cos2SigmaM = cosSigma - 2*sinU1*sinU2 / cosSqAlpha
      if (is.nan(cos2SigmaM))
        cos2SigmaM = 0  ## equatorial line: cosSqAlpha=0 (§6)
      C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha))
      lambdaP = lambda
      lambda = L + (1-C) * f * sinAlpha *
        (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)))
      iterLimit = iterLimit - 1
      if (abs(lambda-lambdaP) <= 1e-12 || iterLimit == 0)
        break
    } 
    
    if (iterLimit==0) {
      s[i] = NaN  ## formula failed to converge
    } else if (s[i] < 0) {
      uSq = cosSqAlpha * (a*a - b*b) / (b*b)
      A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
      B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))
      deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                                                 B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)))
      s[i] = b*A*(sigma-deltaSigma)
    }
  }
  s = round(s, 3)
  return (s)
}
