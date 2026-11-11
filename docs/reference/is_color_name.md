# Is it a named color?

Tests membership in a curated set of common color WORDS (CSS/X11 named
colors plus descriptive and hair/eye-color vocabulary). For columns
whose values are color names (`hair_color`, `eye_color`) rather than
hex/rgb codes. The symbol detectors
([`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md)
etc.) handle coded colors; this one handles words.

## Usage

``` r
is_color_name(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a known color word or an all-color compound
(case-insensitive), `FALSE` otherwise, `NA` where `x` is `NA`.

## Details

Compound values count too: a value whose parts are **all** color words
(`"brown, grey"`, `"blue-gray"`, `"dark brown"`) is a color, so hair/eye
columns that mix single and compound colors still read as colors. A
multi-word phrase that is itself in the lexicon (`"salt and pepper"`) is
matched whole first. Non-color fillers (`"none"`, `"unknown"`) are
`FALSE`.

## See also

[`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other color detectors:
[`is_cmyk_color()`](https://lecy.github.io/formex/reference/is_cmyk_color.md),
[`is_hex_color()`](https://lecy.github.io/formex/reference/is_hex_color.md),
[`is_hsl_color()`](https://lecy.github.io/formex/reference/is_hsl_color.md),
[`is_rgb_color()`](https://lecy.github.io/formex/reference/is_rgb_color.md)

## Examples

``` r
is_color_name(c("Brown", "brown, grey", "blue-gray", "Chicago", NA))
#> [1]  TRUE  TRUE  TRUE FALSE    NA
#> TRUE TRUE TRUE FALSE NA
```
