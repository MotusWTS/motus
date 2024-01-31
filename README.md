<!-- badges: start -->
[![:name status badge](https://birdscanada.r-universe.dev/badges/:name)](https://birdscanada.r-universe.dev/)
[![motus status badge](https://birdscanada.r-universe.dev/badges/motus)](https://birdscanada.r-universe.dev/motus)
[![R-CMD-check](https://github.com/MotusWTS/motus/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MotusWTS/motus/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://app.codecov.io/gh/MotusWTS/motus/branch/main/graph/badge.svg)](https://app.codecov.io/gh/MotusWTS/motus?branch=main)

<!-- badges: end -->

# motus
<p align = "center">
  <a href = "https://www.birdscanada.org"><img src = "inst/assets/birds_canada_logo.png" alt = "Birds Canada Logo showing grey text 'Birds Canada' and 'Oiseaux Canada' on either side of a grey and yellow bird perched on a branch" width = "40%"></a>
  <a href = "https://motus.org"><img src = "inst/assets/motus_logo.png" alt = "Motus Logo showing blue text 'Motus Wildlife Tracking System' to the right of pale green images of a bat, bird and dragonfly at the ends of green curved lines"></a>
</p>

An R package for handling [Motus](https://motus.org) automated radio-telemetry data.

See the [motus package site](https://motuswts.github.io/motus/) for detailed usage information.


## Installation

The easiest way to install motus is from Birds Canada's [R-Universe](https://birdscanada.r-universe.dev):

```R
install.packages("motus", 
                 repos = c(birdscanada = 'https://birdscanada.r-universe.dev',
                           CRAN = 'https://cloud.r-project.org'))
```

If you want to check out work-in-progress, you can install the development 
branches (betaX and sandbox) using `remotes`.
```R
install.packages("remotes")                     # if don't already have it
remotes::install_github("motusWTS/motus@beta3") # the beta branch for v3+
```

> Running into problems? Check out the [Troubleshooting article](https://motuswts.github.io/motus/articles/troubleshooting.html)
