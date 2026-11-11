# Is it an MD5 digest?

Is it an MD5 digest?

## Usage

``` r
is_md5(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a 32-character hex string.

## See also

Other hash detectors:
[`is_guid()`](https://lecy.github.io/formex/reference/is_guid.md),
[`is_sha1()`](https://lecy.github.io/formex/reference/is_sha1.md),
[`is_sha256()`](https://lecy.github.io/formex/reference/is_sha256.md)

## Examples

``` r
is_md5(c("d41d8cd98f00b204e9800998ecf8427e", "abc", NA))
#> [1]  TRUE FALSE    NA
```
