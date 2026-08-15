# formex

<!-- badges: start -->
<!-- badges: end -->

**formex** (*format expressions*) is a vocabulary + detection + transformation
engine for the column types found in research data. Point it at a column and it
tells you *what the values are* — a calendar date, an ISBN, a US state, a person
name, a currency amount — and then *standardizes them* to a stable, analysis-ready
form.

It is built around a versioned **ontology** of semantic types, a library of
deterministic **detectors**, and a two-stage **router → verifier** classifier
that returns a graceful, confidence-aware answer rather than a forced guess.

## Installation

```r
# install.packages("remotes")
remotes::install_github("lecy/formex")
```

The learned router additionally uses **xgboost** (a soft dependency); without it,
`formex` falls back to a model-free signature router.

## Two entry points

### 1. `guess_data_type()` — what is this column?

```r
library(formex)

guess_data_type(c("03/15/2019", "12/31/2020", "01/01/2021"))$route
#> data_type      "temporal"
#> semantic_family "date"
#> semantic_type   "calendar"
#> format_label    "calendar"
#> depth           4        # resolved all the way to a leaf
#> confidence      1.00
```

The `$route` record anchors the column to the ontology
(`data_type → semantic_family → semantic_type → format_label`) and **truncates
gracefully**: when the values cannot pin a leaf, it stops at the deepest level it
can actually defend (`depth` 0–4). The legacy detector-based fields
(`$guess`, `$ontology`) are returned alongside, unchanged.

### 2. `fx_stabilize()` — put it in a standard form

```r
fx_stabilize(c("isbn 0395629764", "ISBN 957-33-0471-6"),
             "administrative", "isbn")$stable
#> "0395629764" "9573304716"

fx_stabilize(c("California", "TX", "Ohio"), "geographic", "us_state")$stable
#> "CA" "TX" "OH"
```

Each ontology row carries a recipe (a small transform DSL) that normalizes the
raw values and reports the stable format + import rule.

## How it works

- **Router** (Stage 1) shortlists candidate semantic types. Two ship: a learned
  xgboost model over the full value profile (`fx_extract_features()`), and a
  model-free signature router. `guess_data_type(router=)` picks the strategy.
- **Verifier** (Stage 2) confirms a leaf deterministically with
  *confirm = detect ∘ transform*, gated by a foil-selectivity test so permissive
  types truncate instead of claiming a false leaf.
- **Ontology** (`fx_ontology()`) is the shared vocabulary — stable
  `semantic_type_id`s and per-type recipes — that `guess_data_type()` and
  `fx_stabilize()` both speak.

## Gazetteers & licensing

The shipped person/place gazetteers are public-domain: the top 1000 SSA given
names (CC0, via `babynames`) and the top 2000 US Census 2010 surnames. See
`data-raw/gazetteers.R` to regenerate them.
