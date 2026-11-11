# Is it an ISO 4217 currency code?

Tests whether each element is a valid three-letter ISO 4217 currency
code (e.g. `"USD"`, `"eur"`). Matching is case-insensitive.

## Usage

``` r
is_currency_code(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector the same length as `x`: `TRUE` where the value is a
valid ISO 4217 code, `FALSE` otherwise, `NA` where `x` is `NA`.

## Details

A code-list lookup, not a syntactic check: `"ZZZ"` has the right shape
but is not a real code and returns `FALSE`.

## See also

[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md),
[`is_currency_code_symbol()`](https://lecy.github.io/formex/reference/is_currency_code_symbol.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other currency detectors:
[`is_currency_amount()`](https://lecy.github.io/formex/reference/is_currency_amount.md),
[`is_currency_code_symbol()`](https://lecy.github.io/formex/reference/is_currency_code_symbol.md),
[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md)

## Examples

``` r
is_currency_code(c("USD", "eur", "ZZZ", NA))
#> [1]  TRUE  TRUE FALSE    NA
#> TRUE TRUE FALSE NA
```
