# motus
R package for users of data from http://motus.org

See the [Motus R book](http://motus.org/MotusRBook/) for detailed usage information


## Installation

### Updating

If you are updating your version of `motus` from a version <1.5.0 to >= 1.5.0 (i.e. from when `motusClient` was a separate package), you will have best results if you first remove `motus` and `motusClient` and reinstall from scratch:

```R
remove.packages(c("motus", "motusClient"))
```

Now you can install v1.5.0+ as follows.

### New Installation

**Users**: the 'master' branch is what you want.  You can install it
from R by doing:
```R
install.packages("remotes")              ## if you haven't already done this
remotes::install_github("motusWTS/motus@master")   ## the lastest stable version
```

**Developers**: the 'staging' branch is for work-in-progress.  Install it with
```R
install.packages("remotes")               ## if you haven't already done this
remotes::install_github("motusWTS/motus@staging")   ## the development version
```