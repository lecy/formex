# Is it an Ensembl gene/transcript/protein ID?

Is it an Ensembl gene/transcript/protein ID?

## Usage

``` r
is_ensembl_id(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `ENS[species]<G/T/P/E><11 digits>`.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_ensembl_id(c("ENSG00000139618", "ENSMUSG00000102659", NA))
#> [1] TRUE TRUE   NA
```
