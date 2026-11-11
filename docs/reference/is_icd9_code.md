# Is it an ICD-9 code?

Is it an ICD-9 code?

## Usage

``` r
is_icd9_code(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a numeric or E/V ICD-9-CM code.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_icd9_code(c("078.11", "V70.0", "E880.9", NA))
#> [1] TRUE TRUE TRUE   NA
```
