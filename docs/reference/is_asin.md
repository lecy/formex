# Is it an Amazon ASIN?

Is it an Amazon ASIN?

## Usage

``` r
is_asin(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a `B0` + 8 alphanumeric ASIN.

## See also

Other scibio detectors:
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_asin(c("B01L7DYXL0", "B08N5WRWNW", "140955525", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
