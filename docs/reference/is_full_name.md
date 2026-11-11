# Is it a person's full name?

Recognizes `First [Middle] Last` (given-name led) and
`Last, First [Middle]` shapes of two to four tokens, requiring at least
one token to be a known given name or surname so arbitrary two-word
phrases do not match. Middle initials (`J.`) and internal punctuation
are tolerated.

## Usage

``` r
is_full_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a plausible full name.

## See also

Other person detectors:
[`is_first_name()`](https://lecy.github.io/formex/reference/is_first_name.md),
[`is_last_name()`](https://lecy.github.io/formex/reference/is_last_name.md)

## Examples

``` r
is_full_name(c("John Smith", "Garcia, Maria", "Mary J. Cooper", "New York", NA))
#> [1]  TRUE  TRUE  TRUE FALSE    NA
```
