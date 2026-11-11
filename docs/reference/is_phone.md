# Is it a US / NANP phone number?

Is it a US / NANP phone number?

## Usage

``` r
is_phone(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for common US formats such as `510-577-3201`,
`(309) 647-1820`, `1-650-384-9911`, `650 231 1123`.

## See also

Other phone detectors:
[`is_intl_phone()`](https://lecy.github.io/formex/reference/is_intl_phone.md),
[`is_msisdn()`](https://lecy.github.io/formex/reference/is_msisdn.md)

## Examples

``` r
is_phone(c("(309) 647-1820", "510-577-3201", "12345", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
