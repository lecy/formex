# Surface confusable type pairs through the taxonomy and the data

Compares every pair of types through two lenses – taxonomic distance
([`fx_path_distance()`](https://lecy.github.io/formex/reference/fx_path_distance.md))
and signature distance
([`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md))
– and flags where they disagree. `hidden_risk` pairs (far in the
taxonomy but near in signature space) are the dangerous set that needs
hard negatives banked against each other; `safe_split` pairs are
siblings the data tells apart easily.

## Usage

``` r
fx_sibling_report(
  sigs,
  paths,
  labels = names(paths),
  weights = SIGNATURE_WEIGHTS,
  path_near = 0.34,
  sig_near = 0.1
)
```

## Arguments

- sigs:

  A named list (or matrix of rows) of signatures.

- paths:

  Ontology paths, aligned to `sigs`.

- labels:

  Row labels (default `names(paths)`).

- weights:

  Signature weights (default
  [SIGNATURE_WEIGHTS](https://lecy.github.io/formex/reference/SIGNATURE_WEIGHTS.md)).

- path_near, sig_near:

  Thresholds for taxonomic / signature nearness.

## Value

A data frame of pairs with distances and a `status` column (`both`,
`hidden_risk`, `safe_split`, `unrelated`).

## See also

[`fx_path_distance()`](https://lecy.github.io/formex/reference/fx_path_distance.md),
[`fx_signature_distance()`](https://lecy.github.io/formex/reference/fx_signature_distance.md)
