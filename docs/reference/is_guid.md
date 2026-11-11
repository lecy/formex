# Is it a GUID / UUID?

Is it a GUID / UUID?

## Usage

``` r
is_guid(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for the `8-4-4-4-12` hex UUID form.

## See also

Other hash detectors:
[`is_md5()`](https://lecy.github.io/formex/reference/is_md5.md),
[`is_sha1()`](https://lecy.github.io/formex/reference/is_sha1.md),
[`is_sha256()`](https://lecy.github.io/formex/reference/is_sha256.md)

## Examples

``` r
is_guid(c("f2a59360-1d1a-49e8-9a2f-f9cdf0d5a811", NA))
#> [1] TRUE   NA
```
