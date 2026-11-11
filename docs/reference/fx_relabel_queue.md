# The relabel work list, highest-value first

Every case with `label.needs_relabel = TRUE`, ordered by coverage risk
(types with fewest remaining valid cases first), then difficulty (hard
first), then labelling method (human first). The candidate shortlist is
recomputed from the CURRENT ontology, not reused from the case.

## Usage

``` r
fx_relabel_queue(bank_dir)
```

## Arguments

- bank_dir:

  Directory of schema-v2 case files.

## Value

A data frame of cases needing relabel, ordered.
