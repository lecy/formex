# Building a Feature Dataset for Classification

The
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
router is trained on value-profile features (see
[`vignette("feature-engineering")`](https://lecy.github.io/formex/articles/feature-engineering.md)),
scored against the example corpora (see
[`vignette("testing-libraries")`](https://lecy.github.io/formex/articles/testing-libraries.md)).
This guide shows how those two pieces combine into a single, model-ready
**feature matrix**: one row per column, 477 feature columns, and
ontology labels to predict. It is the dataset the
[`vignette("classifier-decision-tree")`](https://lecy.github.io/formex/articles/classifier-decision-tree.md)
worked examples are built on.

## The modeling unit: a row is a whole column

Each observation is a single *column* of real tabular data — a vector of
values such as `c("AUD", "CAD", "CNY", ...)`.
[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
turns that vector into 477 numbers describing the shape and content of
the *whole column*: its cardinality, character makeup, numeric range,
token vocabulary, and lexicon hits. The classifier learns to recognize a
type from how a column looks, exactly the way the router does at
inference time.

Two choices keep the task honest:

- **No label leakage.** Features are extracted with `col_name = NULL`,
  so the column header never enters the feature set.
- **Ground-truth labels.** The outcome columns come from a crosswalk,
  not from running
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
  — so `features -> type` is a genuine supervised problem, not a model
  trained to imitate the router.

## Three labeled corpora

The builder (`data-raw/build_feature_dataset.R`) draws one row per
column from three sources:

| Corpus | Rows | What it is |
|----|---:|----|
| Sherlock / VizNet | 5,536 | Real web-table columns, each tagged with one of 78 semantic types. Labels derive from headers, so this is a value-only signal. |
| GitTables (dbpedia) | 768 | Columns from GitHub CSV tables annotated against DBpedia properties; headers anonymized to `col0..colN`. |
| formex-native | 86 | The package’s own curated positive examples, one canonical column per detector; adds clean `boolean` and `structured` coverage. |
| **Total** | **6,390** |  |

Sherlock and GitTables labels map to the ontology through the project’s
v4 crosswalk CSVs; the formex detector names map through the shipped
detector-to-ontology chain. All three resolve `data_type`,
`semantic_family`, and `semantic_type`.

A column must clear **8 non-sentinel values** to be profiled — a guard
that drops columns which are entirely sentinel tokens (all `"None"`,
`"UNK"`, `"n/a"`), since those strip to empty and profile to a
degenerate near-empty row.

## What a row holds

``` r

d <- readRDS("data-raw/type_features_dataset.rds")
names(d)[1:10]
#> corpus · source_label · vector_length · sample_values ·
#> data_type · semantic_family · semantic_type · format_label ·
#> format_style · unit_type · <477 feature columns>
```

| Column(s) | Role |
|----|----|
| `corpus`, `source_label` | Provenance: which corpus, and the original label. |
| `vector_length` | Count of usable (non-missing, non-sentinel) values. |
| `sample_values` | Up to five example values, joined by `;;`. |
| `data_type` | Coarse target: `number, text, categorical, temporal, identifier, structured, boolean`. |
| `semantic_family`, `semantic_type` | Finer targets (25 / 40 classes). |
| `format_label`, `format_style`, `unit_type` | Deep ontology format axes — mostly empty, since these semantic corpora do not carry them. |
| 477 feature columns | The value profile (below). |

## 477 features in 12 blocks

[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
computes every block in one pass. A feature that does not apply to a
column is `NA`, never `0`.

| Block | Measures | \# |
|----|----|---:|
| core | Cardinality, uniqueness, entropy, top-value concentration, Zipf fit. | 21 |
| length | String-length distribution, fixed-width flag, token counts. | 23 |
| charclass | Digit / alpha / space / punctuation shares, case patterns. | 22 |
| punct | Per-symbol presence, counts, and positional spread (22 marks). | 118 |
| mask | Pattern abstraction (`123 Main` -\> `9 Aaaa`), delimiter fields. | 21 |
| charfreq | Per-letter & per-digit frequencies, first/last-letter distributions. | 97 |
| regex | ~45 format patterns (email, UUID, dates, money) plus checksums. | 43 |
| numeric | Numeric summaries, range bounds, Benford, distribution fits. | 48 |
| sequence | Numeric order: monotonicity, autoincrement, lag-1 autocorrelation. | 11 |
| token | Token vocabulary, stopword rate, first/last-token stability. | 23 |
| lexicon | Hit rates against gazetteers (names, cities, states, units). | 30 |
| header | Column-name keyword flags & input class — **all NA here** (no headers). | 20 |

## Missing data is “not applicable”, so impute by what absence implies

The matrix is deliberately full of `NA`: numeric statistics are
undefined on text, letter frequencies are undefined on all-digit
columns. For a model that drops rows with any `NA` (plain logistic
regression), impute each feature by the reason it is missing.
`data-raw/make_imputation_spec.R` writes one rule per feature to
`type_features_imputation.csv`:

| Rule | \# | When |
|----|---:|----|
| `zero` | 412 | The structure the feature measures is **absent**, so `FALSE` / zero-rate / zero-count is the true value (sequence flags on text, letter/digit/token/lexicon rates, punctuation-position spread, regex checksums with no candidate). |
| `numeric_med` + indicator | 45 | The `num_*` block, `NA` because the column is not numeric. Impute the training **median** and keep `coerce_rate_strip` as an “is-numeric” indicator, since `0` is a valid number and would forge a measurement. |
| `drop` | 20 | No information: the all-`NA` `nm_*` header features and the constant `in_is_*` flags. |

After this, the metadata columns and the three populated label axes have
no missing values at all.

## Which features fire for a type

For three target types we build a one-vs-rest problem (this type vs. a
500-column sample of everything else) and rank features by univariate
discrimination (AUC).

- **`us_state`** — gazetteer hits and shape: `lex_us_state_abb_value`
  (0.81), `lex_any_value` (0.87), `pct_all_alpha` (0.81), short length.
  A logistic fit on the top signals reaches ~91% — the one example with
  real error, since state names overlap city and country.
- **`email`** — `has_at` and `rx_email` separate perfectly (AUC 1.0). A
  lesson in itself: perfect separation breaks unregularized logistic
  regression, so penalize or read it as a single rule already sufficing.
- **`ein`** — the `NN-NNNNNNN` pattern (`rx_ein`, 1.0), a valid IRS
  prefix (`chk_ein_prefix_rate`, 1.0), the single dash, and the digit
  spread.

## Where the value signal runs out

Not every type has a surface fingerprint, and the dataset makes that
visible:

- **`weight` is the hardest type.** Its one-vs-rest held-out AUC is
  ~0.50 — no better than a coin flip — because a bare number column is
  indistinguishable from any other numeric quantity. Its nearest
  neighbours in feature space are `duration`, `sales`, and `ranking`.
  The type lives in the header, not the values.
- **`city` and `country` are feature twins.** They agree on 384 of ~475
  features (both short, all-alphabetic, title-cased categoricals) and
  are split almost entirely by one gazetteer feature,
  `lex_us_city_value` (fires on 39% of city values vs 0.3% of country
  names). That single feature is why the `lexicon` block exists.

See
[`vignette("classifier-decision-tree")`](https://lecy.github.io/formex/articles/classifier-decision-tree.md)
for the modeling that follows from here.

``` r

# Reproduce the dataset and its companions:
#   source("data-raw/build_feature_dataset.R")   # the 6,390-row feature matrix
#   source("data-raw/make_imputation_spec.R")    # the per-feature NA rules
#   source("data-raw/model_feature_demo.R")      # the one-vs-rest feature rankings
```
