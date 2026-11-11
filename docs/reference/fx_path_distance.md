# Taxonomic distance between two ontology paths

Distance on the `data_type/semantic_family/semantic_type` path: the
fraction of levels that diverge once the shared prefix ends. Same leaf =
0; different `data_type` = 1. Format is deliberately not a level.

## Usage

``` r
fx_path_distance(p1, p2, levels = 3)
```

## Arguments

- p1, p2:

  Slash-separated ontology paths.

- levels:

  Number of path levels to compare (default 3).

## Value

A distance in `[0,1]`.

## See also

[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md),
[`fx_sibling_report()`](https://lecy.github.io/formex/reference/fx_sibling_report.md)
