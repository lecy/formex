# Is it an HSL triple?

Is it an HSL triple?

## Usage

``` r
is_hsl_color(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `H, S%, L%` with hue 0-360 and S/L 0-100%.

## See also

Other color detectors:
[`is_cmyk_color()`](https://lecy.github.io/formex/reference/is_cmyk_color.md),
[`is_color_name()`](https://lecy.github.io/formex/reference/is_color_name.md),
[`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md),
[`is_rgb_color()`](https://lecy.github.io/formex/reference/is_rgb_color.md)

## Examples

``` r
is_hsl_color(c("195, 100%, 27%", "0, 0%, 0%", "195, 100, 27", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
