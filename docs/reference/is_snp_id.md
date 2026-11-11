# Is it a dbSNP reference SNP ID?

Is it a dbSNP reference SNP ID?

## Usage

``` r
is_snp_id(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `rs` followed by digits.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_snp_id(c("rs3918290", "rs429358", "3918290", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
