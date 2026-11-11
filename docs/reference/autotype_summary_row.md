# One master-table row for a data type

One master-table row for a data type

## Usage

``` r
autotype_summary_row(type_label, P, results, n_examples = 3)
```

## Arguments

- type_label:

  A human-readable label for the type.

- P:

  The positive examples (for the Example column).

- results:

  Output of
  [`build_autotype_results()`](https://lecy.github.io/formex/reference/build_autotype_results.md).

- n_examples:

  Number of example positives to show.

## Value

A one-row data frame: `Type`, `Example`, `Recall`, `S1`-`SP`.
