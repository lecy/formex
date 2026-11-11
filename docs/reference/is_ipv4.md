# Is it an IPv4 address?

Is it an IPv4 address?

## Usage

``` r
is_ipv4(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for four dot-separated octets in 0-255.

## See also

Other web detectors:
[`is_email()`](https://lecy.github.io/formex/reference/is_email.md),
[`is_ipv6()`](https://lecy.github.io/formex/reference/is_ipv6.md),
[`is_mac()`](https://lecy.github.io/formex/reference/is_mac.md),
[`is_url()`](https://lecy.github.io/formex/reference/is_url.md)

## Examples

``` r
is_ipv4(c("192.168.1.1", "256.1.1.1", NA))
#> [1]  TRUE FALSE    NA
```
