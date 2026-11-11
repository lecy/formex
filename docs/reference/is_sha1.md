# Is it a SHA-1 digest?

Is it a SHA-1 digest?

## Usage

``` r
is_sha1(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 40-character hex string.

## See also

Other hash detectors:
[`is_guid()`](https://lecy.github.io/formex/reference/is_guid.md),
[`is_md5()`](https://lecy.github.io/formex/reference/is_md5.md),
[`is_sha256()`](https://lecy.github.io/formex/reference/is_sha256.md)

## Examples

``` r
is_sha1(c("da39a3ee5e6b4b0d3255bfef95601890afd80709", NA))
#> [1] TRUE   NA
```
