# motus

[![Birds Canada Logo showing grey text 'Birds Canada' and 'Oiseaux
Canada' on either side of a grey and yellow bird perched on a
branch](reference/figures/birds_canada_logo.png)](https://www.birdscanada.org)
[![Motus Logo showing blue text 'Motus Wildlife Tracking System' to the
right of pale green images of a bat, bird and dragonfly at the ends of
green curved
lines](reference/figures/motus_logo.png)](https://motus.org)

An R package for handling [Motus](https://motus.org) automated
radio-telemetry data.

See the [motus package site](https://motuswts.github.io/motus/) for
detailed usage information.

## Installation

The easiest way to install motus is from Birds Canada’s
[R-Universe](https://birdscanada.r-universe.dev):

``` r
install.packages("motus", 
                 repos = c(birdscanada = 'https://birdscanada.r-universe.dev',
                           CRAN = 'https://cloud.r-project.org'))
```

If you want to check out work-in-progress, you can install the
development branches (betaX and sandbox) using `remotes`.

``` r
install.packages("remotes")                     # if don't already have it
remotes::install_github("motusWTS/motus@beta3") # the beta branch for v3+
```

> Running into problems? Check out the [Troubleshooting
> article](https://motuswts.github.io/motus/articles/troubleshooting.html)
