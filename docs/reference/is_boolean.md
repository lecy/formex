# Is it a boolean / indicator value?

Is it a boolean / indicator value?

## Usage

``` r
is_boolean(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a recognized two-state token (`true`/`false`,
`t`/`f`, `yes`/`no`, `y`/`n`, `1`/`0`), case-insensitive. Whether the
column is genuinely binary is a column-level property; this is a
per-value membership test.

## Examples

``` r
is_boolean(c("TRUE", "no", "Y", "0", "maybe", NA))
#> [1]  TRUE  TRUE  TRUE  TRUE FALSE    NA
```
