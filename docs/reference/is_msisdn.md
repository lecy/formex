# Is it an MSISDN (mobile subscriber number)?

Is it an MSISDN (mobile subscriber number)?

## Usage

``` r
is_msisdn(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a bare 10-15 digit MSISDN.

## Details

Loose by construction: any 10-15 digit run matches. Best used with a
variable-name hint.

## See also

Other phone detectors:
[`is_intl_phone()`](https://lecy.github.io/formex/reference/is_intl_phone.md),
[`is_phone()`](https://lecy.github.io/formex/reference/is_phone.md)

## Examples

``` r
is_msisdn(c("919961345678", "13109976224", "12345", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
