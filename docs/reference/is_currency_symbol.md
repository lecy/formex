# Is it a currency symbol + amount?

Tests whether each element is a currency symbol immediately followed by
a numeric amount with at most two decimals, e.g. `"$12.30"`,
`"€299.10"`, `"¥1222"`, `"£49.99"`. Recognised symbols are `$`, `€`
(euro), `¥` (yen), and `£` (pound).

## Usage

``` r
is_currency_symbol(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector the same length as `x`: `TRUE` where the value matches
the symbol+amount pattern, `FALSE` otherwise, `NA` where `x` is `NA`.

## Details

Rejects thousands separators (`"$1,000"`), more than two decimals
(`"$1.234"`), and a bare symbol (`"$"`). Extend the character class in
the regex to admit more symbols.

## See also

[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`is_currency_code_symbol()`](https://lecy.github.io/formex/reference/is_currency_code_symbol.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other currency detectors:
[`is_currency_amount()`](https://lecy.github.io/formex/reference/is_currency_amount.md),
[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`is_currency_code_symbol()`](https://lecy.github.io/formex/reference/is_currency_code_symbol.md)

## Examples

``` r
is_currency_symbol(c("$12.30", "¥1222", "$1,000", "$", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
#> TRUE TRUE FALSE FALSE NA
```
