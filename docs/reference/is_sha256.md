# Is it a SHA-256 digest?

Is it a SHA-256 digest?

## Usage

``` r
is_sha256(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 64-character hex string.

## See also

Other hash detectors:
[`is_guid()`](https://lecy.github.io/formex/reference/is_guid.md),
[`is_md5()`](https://lecy.github.io/formex/reference/is_md5.md),
[`is_sha1()`](https://lecy.github.io/formex/reference/is_sha1.md)

## Examples

``` r
is_sha256(c(paste(rep("a", 64), collapse = ""), NA))
#> [1] TRUE   NA
```
