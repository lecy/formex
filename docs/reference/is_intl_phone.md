# Is it an international (+ prefixed) phone number?

Is it an international (+ prefixed) phone number?

## Usage

``` r
is_intl_phone(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a `+`-prefixed number with 8-15 digits and
common separators/parentheses.

## See also

Other phone detectors:
[`is_msisdn()`](https://lecy.github.io/formex/reference/is_msisdn.md),
[`is_phone()`](https://lecy.github.io/formex/reference/is_phone.md)

## Examples

``` r
is_intl_phone(c("+1-4250013981", "+61 3 6216 0864", "4250013981", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
