# Score one ontology assignment by feasibility

Score one ontology assignment by feasibility

## Usage

``` r
feasibility_score(pred, ideal, feasible_depth, pred_unit = NA, ideal_unit = NA)
```

## Arguments

- pred:

  Character length-3 `c(type, class, subclass)`; use `NA`/`""` for
  levels the detector did not reach.

- ideal:

  Character length-3 `c(type, class, subclass)` from the crosswalk;
  all-empty means a NULL target (no formex home).

- feasible_depth:

  Integer 0-3: deepest level reachable from values on the ideal path (0
  none, 1 type, 2 class, 3 subclass).

- pred_unit, ideal_unit:

  Optional unit/system/projection strings for the unit-recovery flag.

## Value

A list with `score` (0/1/2) and `unit_recovered` (0/1/`NA`).
