# The research data-type ontology (v7)

The research data-type ontology (v7)

## Usage

``` r
fx_ontology()
```

## Value

A data frame of ontology rows (one per format variant), with the
load-bearing identity columns `semantic_type_id`, `variant_id`,
`node_label`, the path columns `data_type` / `semantic_family` /
`semantic_type`, and lifecycle columns (`version_added`,
`version_deprecated`, `superseded_by`).

## See also

[`fx_validate_ontology()`](https://lecy.github.io/formex/reference/fx_validate_ontology.md)
