# Classify the differences between two ontology versions

Every difference is reduced to a `change_kind` with a determinate blast
radius, keyed on `semantic_type_id` (never on path text).

## Usage

``` r
fx_ontology_diff(old, new)
```

## Arguments

- old, new:

  Ontology data frames, or paths to ontology CSVs. Both must carry
  `semantic_type_id`, `variant_id`, `data_type`, `semantic_family`,
  `semantic_type`, `version_deprecated`, `superseded_by`.

## Value

A data frame, one row per change: `semantic_type_id`, `change_kind`,
`from_path`, `to_path`, `case_impact`, `scoring_impact`, `note`.

## See also

[`fx_impacted_cases()`](https://lecy.github.io/formex/reference/fx_impacted_cases.md),
[`fx_ontology_impact_table()`](https://lecy.github.io/formex/reference/fx_ontology_impact_table.md)
