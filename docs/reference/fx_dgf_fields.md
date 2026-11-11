# Format a type prediction as governance-file (DGF) fields

Produces the eight per-variable fields the DGF expects. Supply as much
of the path as the detector could resolve; deeper levels left `NA` are a
legitimate shallow (graceful) prediction, reflected in `depth_labeled`.

## Usage

``` r
fx_dgf_fields(
  data_type = NA,
  semantic_family = NA,
  semantic_type = NA,
  semantic_type_id = NA,
  confidence = NA_real_,
  detector_id = NA,
  ontology_version = "v6",
  ont = NULL
)
```

## Arguments

- data_type, semantic_family, semantic_type:

  The resolved path prefix; any suffix may be `NA`.

- semantic_type_id:

  If given (and the path is not), the path is resolved from the
  ontology.

- confidence:

  Detector confidence in `[0,1]`, or `NA`.

- detector_id:

  Identifier of the detector that produced the guess, so a bad detector
  can be traced through the variables it touched.

- ontology_version:

  The ontology version the guess was made against; stored so a version
  bump can invalidate the guess (§5.2).

- ont:

  Ontology table for id resolution (defaults to
  [`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)).

## Value

A one-row data frame with `data_type`, `semantic_family`,
`semantic_type`, `semantic_type_id`, `depth_labeled`, `confidence`,
`ontology_version`, `detector_id`.
