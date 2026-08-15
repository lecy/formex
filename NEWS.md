# formex 0.0.0.9000

* Two-stage `guess_data_type()` (router → verifier), anchored to the v6
  ontology and returned as a `$route` record alongside the unchanged legacy
  fields:
  - **Router** shortlists candidates. Ships two: a model-free signature router
    (`fx_type_signature()` + `shortlist_candidates()`) and a learned xgboost
    router over the full `fx_extract_features()` profile
    (`inst/extdata/router_xgb.rds`, trained by `data-raw/train_router.R`). The
    `router=` argument selects `"auto"` (learned, falling back to signature),
    `"learned"`, or `"signature"`; `route$router_method` reports which ran.
    Requires the `xgboost` Suggests; absent it, `"auto"` degrades to signature.
  - **Verifier** confirms a leaf with confirm = detect ∘ transform, gated by an
    empirical foil-selectivity test so permissive recipes (numeric subtypes,
    free text) truncate to their data_type instead of claiming a false leaf.
    Tolerant temporal recipes are separated by the column's own time/date
    content.
  - Result **gracefully truncates** to a path prefix (`depth` 0–4) rather than
    forcing a leaf.
* Person/place gazetteers are now public-domain and much larger: `.first_names`
  is the top 1000 SSA given names (CC0, via `babynames`) and `.last_names` the
  top 2000 US Census 2010 surnames (public domain), both regenerable from
  `data-raw/gazetteers.R`. `default_lexicons()` gains shipped first-name,
  last-name, and US-city lists — the learned router's strongest features
  (`lex_first_name_token` ranks #1 by gain).

* New detector batch (8 detectors, 5 ontology classes across 2 new top-level
  families):
  - person names — `is_first_name()`, `is_last_name()`, `is_full_name()`,
    matched against internal SSA given-name and Census surname gazetteers
    (`R/dt-name-data.R`); all map to `text/line/person_name`.
  - `is_boolean()` — two-state indicator (`boolean/binary/indicator`), the first
    detector in the new `boolean` family.
  - `is_wkt_geometry()` — WKT spatial literals (`structured/spatial/geometry`),
    the first detector in the new `structured` family.
  - `is_quarter()`, `is_day_of_week()`, `is_month_of_year()` — new temporal
    classes (`period/quarter`, `phase/day_of_week`, `phase/month_of_year`).
* Wave 2 (4 detectors):
  - `is_fiscal_year()` — FY-labelled years and crossover spans
    (`temporal/period/year`); bare four-digit years are intentionally excluded
    as value-indistinguishable from counts/IDs.
  - `is_geojson()`, `is_wkb()` — GeoJSON and hex WKB/EWKB, extending the
    `structured/spatial/geometry` family alongside `is_wkt_geometry()`.
  - `is_json()` — JSON object/array literals (`text/block/serialized_text`);
    marked loose so `is_geojson()` claims spatial JSON.
* Variable-name classifier (prototype) — the name-side complement to the value
  detectors, for the metadata-gated classes values cannot reveal (weight, rate,
  estimate, standard error, boolean roles, ...):
  - `classify_by_name()` maps a header to an ontology class via an internal
    keyword lexicon (`.name_lexicon`); `.tokenize_name()` normalizes
    camelCase/snake/punctuation headers.
  - `guess_column()` reconciles both modalities VALUES-FIRST: a confident value
    detector wins; the name classifier fills in only when no value detector
    fires, so a misleading name can never override a real value signature.
  - Every lexicon coordinate is asserted to be a valid catalog class.
* External-corpus evaluation harness — `evaluate_columns()` / `eval_summary()`
  score formex against a labeled column corpus via a source-vocabulary
  crosswalk, reporting per-class precision/recall/F1. Ships a Sherlock/VizNet
  78-type -> formex crosswalk (`data-raw/eval/sherlock-crosswalk.R`) and a
  runnable ingest+score script (`data-raw/eval/run-sherlock-eval.R`). Value-only
  by default (Sherlock labels derive from headers); `use_name = TRUE` enables
  the name side for corpora with independent headers (e.g. GitTables).
* Initial extraction from `datagoodr` (at tag `v0.1.0-monolith`).
* Detector families: address, codes, color, currency, datetime, geography,
  government IDs, hashes, phone, research/scholarly IDs, science/bio IDs, web.
* `guess_data_type()` / `score_data_type()` — the dispatchable detection entry
  point, backed by a data-type registry and the type/class/subclass ontology.
* AutoType test-case generation and detector benchmarking
  (`generate_autotype_test_cases()`, `build_autotype_results()`).
* `as_*` format helpers and the *formex* format-expression syntax.
* Bundled data: `data_type_tests` (frozen detector fixture) and internal
  geography/code lookups; regenerate via `data-raw/build_lookups.R` and
  `data-raw/build_test_cases.R`.
