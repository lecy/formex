# Is it a URL?

Is it a URL?

## Usage

``` r
is_url(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for an http/https/ftp URL with a dotted host.

## See also

Other web detectors:
[`is_email()`](https://lecy.github.io/formex/reference/is_email.md),
[`is_ipv4()`](https://lecy.github.io/formex/reference/is_ipv4.md),
[`is_ipv6()`](https://lecy.github.io/formex/reference/is_ipv6.md),
[`is_mac()`](https://lecy.github.io/formex/reference/is_mac.md)

## Examples

``` r
is_url(c("https://example.com/p?q=1", "example.com", NA))
#> [1]  TRUE FALSE    NA
```
