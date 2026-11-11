# Research data-type ontology (v7), parsed

The lazy-loaded copy of
`inst/extdata/research_data_type_ontology_v7.csv`. Identical to
[`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md);
provided for direct `formex::ontology` access.

## Usage

``` r
ontology
```

## Format

A data frame with one row per import recipe (`format_label`), keyed by
`semantic_type_id` + `variant_id`; `match_kind` names the detector-build
strategy (genome/mask/lexicon/mask+lexicon/shape/none).

## Source

`inst/extdata/research_data_type_ontology_v7.csv`
