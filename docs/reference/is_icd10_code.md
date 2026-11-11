# Is it an ICD-10 code?

Is it an ICD-10 code?

## Usage

``` r
is_icd10_code(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `<letter><2 digits>[.<up to 4 alnum>]`.

## See also

Other scibio detectors:
[`is_asin()`](https://lecy.github.io/formex/reference/is_asin.md),
[`is_bibcode()`](https://lecy.github.io/formex/reference/is_bibcode.md),
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md),
[`is_icd9_code()`](https://lecy.github.io/formex/reference/is_icd9_code.md),
[`is_snp_id()`](https://lecy.github.io/formex/reference/is_snp_id.md),
[`is_uniprot_id()`](https://lecy.github.io/formex/reference/is_uniprot_id.md)

## Examples

``` r
is_icd10_code(c("I61", "D76.0", "S72.001A", NA))
#> [1] TRUE TRUE TRUE   NA
```
