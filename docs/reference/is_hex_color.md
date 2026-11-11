# Is it a hex color?

Is it a hex color?

## Usage

``` r
is_hex_color(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `#RGB` or `#RRGGBB`.

## See also

Other color detectors:
[`is_cmyk_color()`](https://lecy.github.io/formex/reference/is_cmyk_color.md),
[`is_color_name()`](https://lecy.github.io/formex/reference/is_color_name.md),
[`is_hsl_color()`](https://lecy.github.io/formex/reference/is_hsl_color.md),
[`is_rgb_color()`](https://lecy.github.io/formex/reference/is_rgb_color.md)

## Examples

``` r
is_hex_color(c("#4d9cf8", "#fff", "4d9cf8", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
