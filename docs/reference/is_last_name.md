# Is it a common US surname (last name)?

Is it a common US surname (last name)?

## Usage

``` r
is_last_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a single token matching the internal Census
surname list (`.last_names`), case- and punctuation-insensitive.

## See also

Other person detectors:
[`is_first_name()`](https://lecy.github.io/formex/reference/is_first_name.md),
[`is_full_name()`](https://lecy.github.io/formex/reference/is_full_name.md)

## Examples

``` r
is_last_name(c("Smith", "garcia", "Xqzzy", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
