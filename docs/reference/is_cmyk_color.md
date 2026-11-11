# Is it a CMYK quadruple?

Is it a CMYK quadruple?

## Usage

``` r
is_cmyk_color(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for four comma-separated values in 0-1.

## See also

Other color detectors:
[`is_color_name()`](https://lecy.github.io/formex/reference/is_color_name.md),
[`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md),
[`is_hsl_color()`](https://lecy.github.io/formex/reference/is_hsl_color.md),
[`is_rgb_color()`](https://lecy.github.io/formex/reference/is_rgb_color.md)

## Examples

``` r
is_cmyk_color(c("0.0,0.31,0.37,0.0", "1,1,1,1", "0,0,0", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
