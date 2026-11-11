# Is it an ADS bibcode?

Is it an ADS bibcode?

## Usage

``` r
is_bibcode(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for the 19-character ADS bibcode form.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd10_code()`](https://lecy.github.io/formex/reference/is_icd10_code.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_bibcode(c("2004PASP..116...98K", "2003A&A...405..175M", NA))
#> [1] TRUE TRUE   NA
```
