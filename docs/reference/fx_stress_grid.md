# Run the stress-test grid over the benchmark

Perturbs every column in `data` along each requested dimension and
level, then re-scores with the benchmark's per-case scorer. A single
shared `clean` baseline per case is emitted (`dimension = "(clean)"`),
so decay is measured relative to it.

## Usage

``` r
fx_stress_grid(
  data = fx_benchmark_data(),
  dimensions = NULL,
  router = "auto",
  reps = 1L,
  seed = 1L,
  max_n = 300L,
  contamination_sweep = FALSE,
  length_min_unique = 10L,
  progress = FALSE
)
```

## Arguments

- data:

  A benchmark data frame from
  [`fx_benchmark_data()`](https://lecy.github.io/formex/reference/fx_benchmark_data.md).

- dimensions:

  Which dimensions to run (default: all).

- router:

  Router passed to
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md).

- reps:

  Repetitions per (case, dimension, level) for stochastic dimensions.

- seed:

  Base seed (per-cell seeds are derived from it, so runs reproduce).

- max_n:

  Cap on the reconstructed / resampled column length.

- contamination_sweep:

  If `TRUE`, also run contamination at 0.4 and 0.5 to locate the
  breaking point (see
  [`fx_contamination_curve()`](https://lecy.github.io/formex/reference/fx_contamination_curve.md)).

- length_min_unique:

  Minimum distinct values for the `length` dimension to apply to a case
  (others are recorded with `applicable = FALSE`).

- progress:

  If `TRUE`, print a progress dot every 200 runs.

## Value

A long data frame:
`case_id, gold_data_type, gold_variant_id, dimension, level, rep, applicable, foil_type`,
the per-level `*_correct` flags, `headline`, `outcome`, and
`elapsed_sec`.

## See also

[`fx_stress_summary()`](https://lecy.github.io/formex/reference/fx_stress_summary.md),
[`fx_contamination_curve()`](https://lecy.github.io/formex/reference/fx_contamination_curve.md),
[`fx_perturb()`](https://lecy.github.io/formex/reference/fx_perturb.md)
