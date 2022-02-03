<!-- badges: start -->
[![R build status](https://github.com/MotusWTS/motus/workflows/R-CMD-check/badge.svg)](https://github.com/MotusWTS/motus/actions)
[![Codecov test coverage](https://codecov.io/gh/MotusWTS/motus/branch/master/graph/badge.svg)](https://codecov.io/gh/MotusWTS/motus?branch=master)
<!-- badges: end -->

# motus
<p align = "center">
  <a href = "https://birdscanada.org"><img src = "https://github.com/MotusWTS/motus/blob/master/inst/assets/birds_canada_logo.png?raw=true" alt = "Birds Canada Logo showing grey text 'Birds Canada' and 'Oiseaux Canada' on either side of a grey and yellow bird perched on a branch" width = "40%"></a>
  <a href = "https://motus.org"><img src = "https://github.com/MotusWTS/motus/blob/master/inst/assets/motus_logo.png?raw=true" alt = "Motus Logo showing blue text 'Motus Wildlife Tracking System' to the right of pale green images of a bat, bird and dragonfly at the ends of green curved lines"></a>
</p>

An R package for handling [Motus](https://motus.org) automated radio-telemetry data.

See the [motus package site](https://MotusWTS.github.io/motus) for detailed usage information.


## Installation

```R
install.packages("remotes")                 # if don't already have it
remotes::install_github("motusWTS/motus")   # the lastest stable version
```

The development branches (betaX and sandbox) are for work-in-progress
```R
install.packages("remotes")                     # if don't already have it
remotes::install_github("motusWTS/motus@beta3") # the beta branch for v3+
```

> Running into problems? Check out the [Troubleshooting article](https://motuswts.github.io/motus/articles/troubleshoting.html)
