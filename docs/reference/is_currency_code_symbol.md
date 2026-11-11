# Is it a currency code + symbol + amount?

Tests whether each element is an ISO 4217 code immediately followed by a
currency symbol and a numeric amount with at most two decimals, e.g.
`"USD$12.30"`, `"EUR€299.10"`, `"JPY¥22"`, `"GBP£1222"`. The prefix must
be a real ISO 4217 code; the symbol must be one of `$`, `€`, `¥`, `£`.

## Usage

``` r
is_currency_code_symbol(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector the same length as `x`: `TRUE` where both the syntax
matches and the prefix is a valid ISO 4217 code, `FALSE` otherwise, `NA`
where `x` is `NA`.

## Details

The code and symbol are not cross-checked for consistency (e.g.
`"USD€10"` passes), because market data frequently pairs an offshore
symbol with a settlement code.

## See also

[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other currency detectors:
[`is_currency_amount()`](https://lecy.github.io/formex/reference/is_currency_amount.md),
[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md)

## Examples

``` r
is_currency_code_symbol(c("USD$12.30", "ZZZ$1", "USD 10", NA))
#> [1]  TRUE FALSE FALSE    NA
#> TRUE FALSE FALSE NA
```
