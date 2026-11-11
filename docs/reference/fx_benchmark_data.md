# Locate and load the frozen benchmark dataset

Returns the frozen evaluation set used by
[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
and
[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md).
Both the small `"mini"` set and the full set ship with the package, so
this works offline with no setup. `refresh = TRUE` instead downloads a
(possibly newer / larger) full set from a remote host and caches it
under [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html); the
URL comes from `getOption("formex.benchmark_url")` or the
`FORMEX_BENCHMARK_URL` environment variable (default: the package's
GitHub release asset). If a requested remote fetch fails, it falls back
to the packaged copy with a message.

## Usage

``` r
fx_benchmark_data(
  which = c("mini", "full"),
  tier = c("all", "clean", "sherlock"),
  refresh = FALSE
)
```

## Arguments

- which:

  `"mini"` (fast, for tests / examples) or `"full"`.

- tier:

  Keep all rows (`"all"`), only the clean banks (`"clean"`), or only the
  vetted Sherlock slice (`"sherlock"`).

- refresh:

  If `TRUE`, (re-)download the full set from the remote host and cache
  it, instead of using the packaged copy.

## Value

A data frame, one row per banked column (see the file header for the
schema), with `benchmark_version` and `built_on` attributes.

## See also

[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md),
[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
