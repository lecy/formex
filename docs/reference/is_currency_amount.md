# Is it a monetary amount?

Tests whether each element is a currency *amount* — a numeric value
carrying a currency symbol (`$`, `€`, `£`, `¥`) as a prefix or suffix,
with optional sign, grouping separators, decimals and interior spaces:
`"$-45"`, `"$2300.00"`, `"17,298$"`, `"2300,00€"`, `"€ 17.298"`,
`"-45€"`, `"$1,000"`.

## Usage

``` r
is_currency_amount(x)
```

## Arguments

- x:

  A character vector of candidate values.

## Value

A logical vector: `TRUE` for a symbol-bearing numeric amount, `FALSE`
otherwise, `NA` where `x` is `NA`.

## Details

The symbol is required. A bare number (`"1234"`, `"-45.10"`) is
deliberately **not** a currency amount at the value level — it is
indistinguishable from a count or any other quantity (that is the
symbol-less `balance` case, which is metadata-gated). Requiring the
symbol is what makes the detector selective.

## See also

[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md),
[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other currency detectors:
[`is_currency_code()`](https://lecy.github.io/formex/reference/is_currency_code.md),
[`is_currency_code_symbol()`](https://lecy.github.io/formex/reference/is_currency_code_symbol.md),
[`is_currency_symbol()`](https://lecy.github.io/formex/reference/is_currency_symbol.md)

## Examples

``` r
is_currency_amount(c("$2300.00", "17,298$", "-45€", "1234", NA))
#> [1]  TRUE  TRUE  TRUE FALSE    NA
#> TRUE TRUE TRUE FALSE NA
```
