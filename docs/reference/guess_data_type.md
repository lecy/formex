# Guess the ontology-anchored data type of a column

Reads up to `n_sample` unique values and returns two aligned views of
the column's type. The LEGACY view scores the values against every
registered detector and reports the best-matching type (when its pass
rate clears `threshold`) with its flat-ontology coordinates. The `route`
view runs the v6 two-stage flow: a signature-based ROUTER shortlists
ontology candidates, then a deterministic VERIFIER (confirm = detect o
transform) confirms a leaf or gracefully truncates to the depth the
router agrees on.

## Usage

``` r
guess_data_type(
  x,
  name = NULL,
  n_sample = 100,
  threshold = 0.8,
  floor = 0.5,
  detectors = data_type_detectors(),
  seed = NULL,
  route = TRUE,
  legacy = TRUE,
  ontology = NULL,
  router_k = 8,
  confirm_thr = 0.8,
  sig_floor = 0.55,
  router = c("auto", "learned", "signature")
)
```

## Arguments

- x:

  A vector (coerced to character) of column values.

- name:

  Optional variable name; used only to break ties (e.g. a column named
  `fips` favors a FIPS detector over a same-shape ZIP detector).

- n_sample:

  Maximum number of unique non-missing values to test.

- threshold:

  Minimum pass rate for the top type to be reported as the legacy
  `guess`; below it, `guess` is `NA` (unknown).

- floor:

  Minimum pass rate for a type to appear in `candidates`.

- detectors:

  A named list of detector functions; defaults to the registry. Unused
  when `legacy = FALSE`.

- seed:

  Optional integer seed for reproducible sampling.

- route:

  If `TRUE` (default), also compute the v6 router-\>verifier `route`
  record. Set `FALSE` to skip it (pure legacy behavior).

- legacy:

  If `TRUE` (default), compute the legacy flat-detector `guess` /
  `ontology` / `candidates` fields. Set `FALSE` to skip that scan and
  return only the `route` record; the legacy fields are still present
  but empty (`guess = NA`, `candidates = NULL`). A speedup for callers
  that read only `$route`, since it avoids scoring every registered
  detector. Setting both `route` and `legacy` to `FALSE` returns an
  empty record.

- ontology:

  The v6 ontology used by the router/verifier; defaults to
  [`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md).

- router_k:

  Router shortlist size (candidates handed to the verifier).

- confirm_thr:

  Minimum verifier confirm rate for a discriminating variant to resolve
  a full leaf (depth 4).

- sig_floor:

  Minimum router similarity for any non-`NA` route guess (signature
  router only).

- router:

  Which Stage-1 router to use: `"auto"` (default) prefers the learned
  xgboost model in `inst/extdata/router_xgb.rds` and falls back to the
  signature router when xgboost or the artifact is unavailable;
  `"learned"` forces the model (route is `NA` if unavailable);
  `"signature"` forces the model-free signature router.
  `route$router_method` reports which ran.

## Value

A list with the legacy fields:

- guess:

  Best-matching detector type name, or `NA`.

- ontology:

  Named vector `c(data_type, data_subtype, data_class, data_format)` for
  the guess (all `NA` if none).

- confidence:

  The guess's pass rate.

- candidates:

  Ranked data frame of types clearing `floor` (`NULL` when
  `legacy = FALSE`).

- n:

  Number of unique values scored.

and, when `route = TRUE`, a `route` sub-list anchored to the v6
ontology: `data_type`, `semantic_family`, `semantic_type`,
`semantic_type_id`, `variant_id`, `format_label`, `format_style` (the v7
written-rendering axis of the resolved variant), `match_kind`, `depth`
(0 = unknown, 1 = data_type, 2 = family, 3 = semantic_type, 4 =
leaf/format), `confidence`, `dd_unit`, and `candidates` (the `router`
shortlist + `verified` table).

## See also

[`score_data_type()`](https://lecy.github.io/formex/reference/score_data_type.md),
[`fx_stabilize()`](https://lecy.github.io/formex/reference/fx_stabilize.md),
[`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)

## Examples

``` r
guess_data_type(c("USD", "EUR", "JPY", "GBP"))$ontology
#>     data_type  data_subtype    data_class   data_format 
#> "categorical"     "nominal"    "category"        "code" 
guess_data_type(c("06037", "36061"), name = "county_fips")$guess
#> [1] "county_fips"
guess_data_type(c("03/15/2019", "12/31/2020"))$route$format_label  # calendar
#> [1] "calendar"
```
