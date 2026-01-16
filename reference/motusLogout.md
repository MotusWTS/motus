# Forget login credentials for motus.

Any requests to the motus data server after calling this function will
require re-entering a username and password.

## Usage

``` r
motusLogout()
```

## Value

TRUE.

## Details

This function just resets these items to NULL:

- motus_vars\$authToken

- motus_vars\$userLogin

- motus_vars\$userPassword

Due to their active bindings, subsequent calls to any functions that
need them will prompt for a login.
