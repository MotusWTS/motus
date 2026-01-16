# Sets global options for timeouts

Sets, resets or returns the "motus.timeout" global option used by all
API access functions (including
[`tagme()`](https://motuswts.github.io/motus/reference/tagme.md)). If
`timeout` is a number and `reset` is `FALSE`, the API timeout is set to
`timeout` number of seconds. If `reset` is `TRUE`, the API timeout is
reset to the default of 120 seconds. If no `timeout` is defined and
`reset = FALSE`, the current value of the timeout is returned.

## Usage

``` r
srvTimeout(timeout, reset = FALSE)
```

## Arguments

- timeout:

  Numeric. Number of seconds to wait for a response from the server.
  Increase if you're working with a project that requires extra time to
  process and serve the data.

- reset:

  Logical. Whether to reset the timeout to the default (120s; default
  `FALSE`). If `TRUE`, `timeout` is ignored.

## Value

Nothing. Or, if `timeout` is missing and `reset = FALSE`, the current
timeout value.

## Details

By default the timeout is 120s, which generally should give the server
sufficient time to prepare the data without having the user wait for too
long if the API is unavailable. However, some projects take unusually
long to compile the data, so a longer timeout may be warranted in those
situations. This is equivalent to `options(motus.timeout = timeout)`

## Examples

``` r
srvTimeout()   # get the timeout value
#> $motus.timeout
#> [1] 120
#> 
srvTimeout(5)  # set the timeout value
srvTimeout()   # get the timeout value
#> $motus.timeout
#> [1] 5
#> 

if (FALSE) { # \dontrun{
# No problem with default timeouts
t <- tagme(176, new = TRUE)

# But setting the timeout too short results in a server timeout
srvTimeout(0.001)
t <- tagme(176, new = TRUE)
} # }
```
