# Is it a UniProt accession?

Is it a UniProt accession?

## Usage

``` r
is_uniprot_id(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a UniProtKB accession pattern.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md)

## Examples

``` r
is_uniprot_id(c("P33667", "Q9BWD1", "ZZ", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
