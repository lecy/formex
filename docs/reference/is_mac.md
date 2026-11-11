# Is it a MAC address?

Is it a MAC address?

## Usage

``` r
is_mac(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for six `:`- or `-`-separated hex octets.

## See also

Other web detectors:
[`is_email()`](https://lecy.github.io/formex/reference/is_email.md),
[`is_ipv4()`](https://lecy.github.io/formex/reference/is_ipv4.md),
[`is_ipv6()`](https://lecy.github.io/formex/reference/is_ipv6.md),
[`is_url()`](https://lecy.github.io/formex/reference/is_url.md)

## Examples

``` r
is_mac(c("00:1B:44:11:3A:B7", "40-1F-3C-B6-3C-BC", NA))
#> [1] TRUE TRUE   NA
```
