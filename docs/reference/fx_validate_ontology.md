# Integrity-check an ontology table

Enforces the invariants that keep banked cases valid across versions
(INTEGRATION §4). Meant to run in `R CMD check`.

## Usage

``` r
fx_validate_ontology(ont = fx_ontology())
```

## Arguments

- ont:

  An ontology data frame (defaults to
  [`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)).

## Value

A character vector of problems; empty (`character(0)`) when valid.

## See also

[`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)
