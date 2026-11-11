# Is it a common US given (first) name?

Is it a common US given (first) name?

## Usage

``` r
is_first_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a single token matching the internal SSA
given-name list (`.first_names`), case- and punctuation-insensitive.

## See also

Other person detectors:
[`is_full_name()`](https://lecy.github.io/formex/reference/is_full_name.md),
[`is_last_name()`](https://lecy.github.io/formex/reference/is_last_name.md)

## Examples

``` r
is_first_name(c("James", "OLIVIA", "Xqzzy", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
