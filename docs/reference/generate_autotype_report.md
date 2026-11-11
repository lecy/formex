# Print an autotype error report for a results table

Reports false negatives (real positives the detector rejected) and up to
`n_examples` false positives per mutation tier (negatives wrongly
accepted).

## Usage

``` r
generate_autotype_report(results, type_name, n_examples = 3)
```

## Arguments

- results:

  Output of
  [`build_autotype_results()`](https://lecy.github.io/formex/reference/build_autotype_results.md).

- type_name:

  A label for the report header.

- n_examples:

  Number of example errors to show per section.

## Value

`results`, invisibly (called for its printed side effect).
