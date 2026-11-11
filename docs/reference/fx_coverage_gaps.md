# Coverage gaps: difficulty-aware flagging of underperforming detectors

The machine-readable companion to the coverage notes in
`DEVELOPMENT-STATUS.md` (§6.5). Rather than a single flat accuracy gate
– which conflates intrinsic difficulty, thin support, and a genuine
detector bug – each gold variant is judged on up to four signals and
sorted into one of two **action buckets**, so every flag names its own
remedy:

## Usage

``` r
fx_coverage_gaps(
  res,
  baseline = NULL,
  stress = NULL,
  min_support = 5L,
  target = .FX_COVERAGE_TARGETS,
  baseline_margin = 0,
  stress_drop_max = 0.25,
  conf = 0.95,
  ontology = fx_ontology(),
  include_absent = TRUE
)
```

## Arguments

- res:

  Output of
  [`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
  (the learned run).

- baseline:

  Optional output of
  [`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
  run with `router = "signature"`, for the baseline-relative signal.
  `NULL` skips it.

- stress:

  Optional output of
  [`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md),
  for the stress-delta signal. `NULL` skips it.

- min_support:

  Variants with fewer than this many cases are `"needs-cases"`.

- target:

  A value-accuracy target: either a single number applied to every
  variant, or a vector named by `match_kind` (default
  `.FX_COVERAGE_TARGETS`: genome/lexicon/mask+lexicon 0.95, mask 0.85,
  shape/none `NA` = excluded).

- baseline_margin:

  Flag `"needs-detector-work"` when `baseline_delta` is below
  `-baseline_margin` (default `0`, i.e. any underperformance).

- stress_drop_max:

  Flag `"needs-detector-work"` when `stress_drop` is at or above this
  (default `0.25`).

- conf:

  Confidence level for the Wilson interval.

- ontology:

  Ontology table providing the `variant_id` -\> `match_kind` map
  (default
  [`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)).

- include_absent:

  If `TRUE` (the default), also emit a `"needs-cases"` row with
  `support = 0` for every **live** ontology variant that never appears
  in `res` — the corpus blind spots the per-case signals cannot see,
  since they only rank variants that were actually banked. Requires an
  `ontology`.

## Value

A data frame per gold variant: `match_kind`, `support`, `acc_type`,
`acc_headline`, `target`, `wilson_upper`, `baseline_acc`,
`baseline_delta`, `stress_drop`, the dominant wrong prediction
(`top_wrong`), and `bucket` (`"needs-detector-work"` / `"needs-cases"` /
`"excluded"` / `"ok"`), ordered worst first. With `include_absent`,
variants absent from the corpus appear as `support == 0` rows in the
`"needs-cases"` bucket.

## Details

1.  **Per-`match_kind` target.** Achievable precision depends on
    mechanism: `genome` / `lexicon` / `mask+lexicon` types can reach
    ~0.95, `mask` is looser, and header-gated `shape` / `none` types are
    **excluded** from value accuracy entirely (never scored 0). The
    target is set by `match_kind` (joined from `ontology`); override via
    `target`.

2.  **Baseline-relative.** With `baseline` (a
    `fx_benchmark(router = "signature")` run), `baseline_delta` is
    learned minus signature accuracy. A type hard for *everyone* is
    difficulty, not a bug; a type where the learned router loses to the
    model-free floor is a real regression.

3.  **Stress-delta.** With `stress` (a
    [`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
    grid), `stress_drop` is the clean type-accuracy minus the mean over
    applicable perturbed rows. Brittleness to a space or stray case is a
    detector bug regardless of absolute accuracy.

4.  **Support-aware confidence.** A Wilson interval on the accuracy
    estimate; the accuracy test fires only when its **upper bound** is
    below target, so thin-support types are not flagged on noise.

Buckets: `"needs-cases"` (thin support -\> bank/generate data), and
`"needs-detector-work"` (adequate support but accuracy upper-bounded
below target, or losing to the signature baseline, or stress-brittle -\>
fix the predicate/recipe). Header-gated types with adequate support are
`"excluded"`; everything else is `"ok"`.

## See also

[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md),
[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md),
[`fx_benchmark_confusion()`](https://lecy.github.io/formex/reference/fx_benchmark_confusion.md)
