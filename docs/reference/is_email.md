# Is it an email address?

Is it an email address?

## Usage

``` r
is_email(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a syntactically valid email, `NA` for `NA`.

## Details

A pragmatic pattern (local `@` domain `.` TLD), not the full RFC 5322
grammar. Rejects spaces and a missing TLD.

## See also

Other web detectors:
[`is_ipv4()`](https://lecy.github.io/formex/reference/is_ipv4.md),
[`is_ipv6()`](https://lecy.github.io/formex/reference/is_ipv6.md),
[`is_mac()`](https://lecy.github.io/formex/reference/is_mac.md),
[`is_url()`](https://lecy.github.io/formex/reference/is_url.md)

## Examples

``` r
is_email(c("a.b@example.com", "no-at-sign", NA))
#> [1]  TRUE FALSE    NA
```
