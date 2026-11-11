# Is it an RGB triple?

Is it an RGB triple?

## Usage

``` r
is_rgb_color(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for three comma-separated integers 0-255.

## See also

Other color detectors:
[`is_cmyk_color()`](https://lecy.github.io/formex/reference/is_cmyk_color.md),
[`is_color_name()`](https://lecy.github.io/formex/reference/is_color_name.md),
[`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md),
[`is_hsl_color()`](https://lecy.github.io/formex/reference/is_hsl_color.md)

## Examples

``` r
is_rgb_color(c("220,220,220", "128, 64, 32", "300,0,0", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
