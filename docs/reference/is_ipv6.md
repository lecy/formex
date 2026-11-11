# Is it an IPv6 address?

Is it an IPv6 address?

## Usage

``` r
is_ipv6(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a full or `::`-compressed IPv6 address.

## See also

Other web detectors:
[`is_email()`](https://lecy.github.io/formex/reference/is_email.md),
[`is_ipv4()`](https://lecy.github.io/formex/reference/is_ipv4.md),
[`is_mac()`](https://lecy.github.io/formex/reference/is_mac.md),
[`is_url()`](https://lecy.github.io/formex/reference/is_url.md)

## Examples

``` r
is_ipv6(c("2001:0db8:85a3:0000:0000:8a2e:0370:7334", "1:2:3", NA))
#> [1]  TRUE FALSE    NA
```
