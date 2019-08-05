# motus
R package for users of data from https://motus.org

See the [Motus R book](https://motus.org/MotusRBook/) for detailed usage information


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

### Troubleshooting

If you run into any installation errors, please ensure that your R packages are up-to-date:

```R
update.packages()
```

Some known installation problems are listed below. If all else fails, uninstalling R and/or R Studio, and reinstalling the latest R version typically works. Depending on how much customization you have made to your R configuration, this may be the quickest option available.

**cannot remove prior installation of package**

If you get errors "cannot remove prior installation of package ..." (e.g. dplyr) while trying to install motus, this could be due to having multiple R sessions active. You can try the following:

1. find out your R package library location: `Sys.getenv("R_LIBS_USER")` or `.libPaths()`
2. close any session of R and/or R Studio
3. in the library folder, manually delete the package that failed to remove (e.g. dplyr)
4. restart R and manually install the package again e.g. `install.packages("dplyr")`

Another possible cause of this problem relates to file permissions in your library folders (e.g. libraries installed in c:\program files\R\R-3.x.x\library\). To confirm this, you can try running R "as administrator" (right-clicking the R icon), or use `SUDO R`  (Linux/Ubuntu) and trying installation again. If this resolves your problem, you should consider setting your libraries in a new folder where your logged in user has full access:

```R
# confirm the libPaths location(s)
.libPaths()
# add a new libPaths default location
.libPaths("c:/users/myusername/R/win-libraries")
```

**certificate errors**

If you get a certificate error using the tagme() function, please ensure that your httr package is up-to-date, as there was a problem reported with one of the recent version that now appears fixed:

```R
remotes::install_github("r-lib/httr")
```
