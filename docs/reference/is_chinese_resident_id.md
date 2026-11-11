# Is it a Chinese resident identity card number?

Is it a Chinese resident identity card number?

## Usage

``` r
is_chinese_resident_id(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for an 18-character ID whose ISO 7064 mod-11-2
check character is valid.

## See also

Other gov detectors:
[`is_dea()`](https://lecy.github.io/formex/reference/is_dea.md),
[`is_ein()`](https://lecy.github.io/formex/reference/is_ein.md),
[`is_naics()`](https://lecy.github.io/formex/reference/is_naics.md),
[`is_ssn()`](https://lecy.github.io/formex/reference/is_ssn.md),
[`is_uei()`](https://lecy.github.io/formex/reference/is_uei.md)

## Examples

``` r
is_chinese_resident_id(c("141002197808194474", NA))
#> [1] TRUE   NA
```
