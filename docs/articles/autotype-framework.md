# The AutoType Framework

Writing a detector that *accepts* real values is easy. The hard part is
*rejecting plausible-but-wrong* ones — a string that is the right data
type but breaks the format. A detector that only ever saw positives has
no way to know whether its rule is too loose. The **AutoType framework**
closes that gap: it synthesizes hard negatives from a handful of
positives, so a detector can be scored for both **recall** (accepts real
values) and **precision** (rejects near-misses). It is the engine behind
the bundled `data_type_tests` fixtures and the stress-test grid, and the
tool you reach for when *refining a mask*. (For the kinds of structure
detectors key on, see
[`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md);
for the catalogue,
[`vignette("data-type-detectors")`](https://lecy.github.io/formex/articles/data-type-detectors.md).)

The method reimplements AutoType (Yan & He, *Auto-Type: Synthesizing
Type-Detection Logic …*, SIGMOD 2018); the functions live in
`R/00-autotype-functions.R`.

## Four tiers of hard negatives

Starting from real positives, AutoType mutates each one into near-misses
along four tiers, each aimed at a different part of the format’s
structure:

| Tier | Name | What it changes | Structure it stresses |
|----|----|----|----|
| **S1** | preserve-structure | replaces only alphanumerics, delimiters stay put | the *values* (often regenerates a valid value for loose types) |
| **S2** | preserve-alphabet | replaces any char, but only with characters seen in the positives | the *arrangement*, staying in-vocabulary |
| **S3** | random | replaces characters with arbitrary printable ASCII | the *alphabet* itself (the easiest negatives) |
| **SP** | scramble-structure | keeps the alphanumerics and their order, **permutes where the punctuation sits** | the *format style directly* |

`SP` is the sharpest tool. It holds the data type constant and attacks
only the *placement* of delimiters — a decimal point, a grouping comma,
a dash in the wrong spot — catching a detector that checks “the right
characters are present” but not “in the right places”. In that sense the
fixtures test **formats more than types**.

## Generating and reading a fixture

Three steps: generate negatives, score a detector, read the report.

``` r

P <- c("ENSG00000139618", "ENSMUSG00000102659", "ENST00000407559")

# one tier at a time ...
generate_autotype_negatives(P, tier = "SP", n_per_positive = 5, seed = 514)

# ... or the full valid + S1/S2/S3/SP fixture as a labelled table
cases <- generate_autotype_test_cases(P, data_type = "ensembl_id")

# score a detector against it and read recall + per-tier false-positive rates
res <- build_autotype_results(is_ensembl_id, P)
autotype_summary(res)
#>    type  n pass_rate
#>   valid  3      1.00   <- recall: must be 1.00
#>      S1 ..      ...    <- share of near-misses WRONGLY accepted (lower better)
#>      S2 ..      ...
#>      S3 ..      ...
#>      SP ..      ...
generate_autotype_report(res, "ensembl_id")   # lists the actual false positives
```

Read the table as:

- **Recall** (the `valid` row) should be **1.00** — a detector that
  rejects real values is broken.
- **S1/S2/S3/SP** are *false-positive* rates: near-misses the detector
  wrongly accepted. Lower is better; blank means the tier produced no
  distinct negatives.
- A **high S1 is expected for loose formats** — mutating the digits of
  `$12.30` to `$47.99` just makes another valid amount. Read S2/S3/SP
  for those.

## Refining a mask

This is the loop the framework is built for. A regex that is too
permissive shows up as **SP false positives**: the characters are right,
the layout is wrong, and the detector accepts it anyway.

``` r

ein <- c("12-3456789", "98-7654321", "04-2103594", "53-0196605", "13-1624016")

# too loose: "any two groups of digits around a dash" also accepts "123-456789"
is_ein_loose <- function(x) grepl("^[0-9]+-[0-9]+$", x)
autotype_summary(build_autotype_results(is_ein_loose, ein))
#> high SP: "12-3456789" scrambled to "123-456789" still passes

# tightened to the real shape: two digits, dash, seven digits
is_ein_tight <- function(x) grepl("^[0-9]{2}-[0-9]{7}$", x)
autotype_summary(build_autotype_results(is_ein_tight, ein))
#> SP drops toward 0; recall stays 1.00
```

Iterate: run the fixture, find the tier that leaks, tighten the rule
toward the *positional* structure (a `{n}` count, an anchored prefix, a
checksum), and re-run until recall is 1.00 and SP is near 0.
[`generate_autotype_report()`](https://lecy.github.io/formex/reference/generate_autotype_report.md)
prints the specific near-misses that still pass, so each iteration has a
concrete target.

## From fixtures to the stress-test grid

The per-detector fixture above tests a detector in isolation. The
production-scale extension perturbs whole *banked columns* and measures
how column-level accuracy decays — an experimental design on top of
[`fx_benchmark()`](https://lecy.github.io/formex/reference/fx_benchmark.md)
(see
[`vignette("benchmarking")`](https://lecy.github.io/formex/articles/benchmarking.md)).
It reuses the same mutation module and adds column-level dimensions,
each at graded levels:

| Dimension | What it does |
|----|----|
| `spelling` | class-preserving substitution (digit↔︎digit, letter↔︎letter) |
| `length` | resample the column to N in {50, 100, 300} |
| `contamination` | mix in foil values from another type (10% / 25%) |
| `whitespace`, `case`, `static` | stray padding, random case folding, stray punctuation |
| `missingness` | inject sentinels (`""`, `NA`, `-`, `null`) |
| `scramble_punct`, `scramble_alnum` | permute punctuation (reuses `SP`) / alphanumerics |

``` r

# perturb a single column along one dimension x level ...
fx_perturb(iso_date, dimension = "scramble_punct", level = "medium", seed = 514)

# ... or run the whole grid over the banked columns and read the decay
grid <- fx_stress_grid()
fx_stress_summary(grid)   # accuracy per dimension x level x data_type
```

Reading the decay per dimension tells you *which* robustness a type
lacks, which points back to exactly the mask-refinement loop above.

## See also

- [`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md)
  — the structures a detector can leverage.
- [`vignette("adding-a-detector")`](https://lecy.github.io/formex/articles/adding-a-detector.md)
  — where the fixture fits in adding a type.
- [`vignette("benchmarking")`](https://lecy.github.io/formex/articles/benchmarking.md)
  — the column-level stress-test grid in full.
