# formex 0.0.0.9000

* **Bug fix: over-long values no longer crash the date machinery.** Base R's
  `strptime()` aborts with `input string is too long` on values over 1000
  bytes, so a single long free-text cell (e.g. a narrative field) made
  `is_date()`, `guess_data_type()` and `fx_stabilize()` error out rather than
  classify the column. Values of 1000 bytes or more are now screened out as
  non-dates before `strptime()` is called -- no real date is anywhere near that
  length -- in both the detector (`is_date()`) and the stabilizer's ISO date
  parser. Reported by datagoodr (B2, `degenerate-columns-and-preflight.md`),
  which can now drop its `.cap_bytes()` workaround.

* **Benchmark + stress-test harness.** A new evaluation layer measures how well
  `guess_data_type()` types columns, over time and under messy data:
  - A frozen benchmark built from the internal test library
    (`data-raw/build_benchmark.R`): one row per banked column with the capped
    values and the gold label at every ontology level. A small stratified set
    ships in the package (`inst/extdata/benchmark_mini.rds`, ~100 cases);
    `fx_benchmark_data()` loads it, or fetches + caches a larger `"full"` set
    from a remote host (`getOption("formex.benchmark_url")` / a GitHub release).
  - `fx_benchmark()` scores each column at `data_type -> semantic_family ->
    semantic_type -> format_style`/`unit` under **hierarchical partial credit**
    (a level counts only if its ancestors match) and records per-case runtime.
  - `fx_benchmark_summary()` reports per-level accuracy, a weighted headline, a
    hit / graceful-truncation / wrong-branch (misroute) mix, by-`data_type`
    accuracy, and runtime stats; `fx_benchmark_confusion()` shows the **shape of
    errors** (where a gold type lands when wrong); `fx_coverage_gaps()` is a
    **difficulty-aware** gap finder (see below); `fx_benchmark_compare()` diffs
    two runs so a change's effect is visible.
  - `fx_stress_grid()` + `fx_perturb()` run a controlled experimental grid:
    each column is perturbed along graded dimensions -- class-preserving
    **spelling** corruption, vector **length** (resample to 50/100/300),
    type-**contamination** (mix a foil type at 10% / 25%, with an optional 0->50%
    sweep), **whitespace**, **case**, **missingness**, **static** punctuation, and
    **position scramble** (punctuation and alphanumeric) -- and re-scored, so
    `fx_stress_summary()` / `fx_contamination_curve()` show the accuracy-decay
    curves and the contamination breaking point. Reuses the AutoType mutators
    (`R/00-autotype-functions.R`).

* **Difficulty-aware `fx_coverage_gaps()`.** The gap finder no longer uses a
  single flat accuracy gate (which conflated intrinsic difficulty, thin support,
  and a real detector bug). It now judges each gold variant on up to four
  signals -- a per-`match_kind` target (header-gated `shape`/`none` types are
  excluded from value accuracy, not scored 0), the Wilson upper bound on the
  accuracy estimate (so thin support is not flagged on noise), the learned
  router's accuracy relative to a signature baseline (optional `baseline=`), and
  the accuracy drop under stress (optional `stress=`) -- and emits an action
  `bucket` (`needs-cases` / `needs-detector-work` / `excluded` / `ok`) in place
  of the old `flag`, so every flagged variant names its own remedy. With
  `include_absent = TRUE` (the default) it also surfaces **live ontology variants
  that never appear in the corpus** as `support == 0` `needs-cases` rows -- the
  coverage blind spots the per-case signals cannot see.

* **Date output styles + style detection.** The transform registry gains a
  vocabulary of calendar written styles (`mdy_slash`, `dmy_slash`, `ymd_dash`,
  `ymd_compact`, `mon_mdy`, `mon_dmy`, …), each readable and writable, so a date
  column stabilizes to any requested style and styles inter-convert (US → EU).
  And `guess_data_type()$route$format_style` now reports the column's **actual**
  detected style (order + separator read from the values; ambiguous all-≤12
  dates default to `mdy_slash`) instead of the generic `calendar`.

* Fixes from the political-org 527 registry (Form 8871):
  - **Email no longer loses to `organization`/`domain`.** The `contact/email`
    leaf joins the verifier's always-on set, so an email column resolves to
    `text/contact/email` (the router was too sparse to shortlist it, and
    `is_email` never competed on content — `is_url` does not match an `@` string).
  - **A 4-digit code is no longer mislabelled a county FIPS.** `as_fips` now
    requires a genuine 5-digit code instead of zero-padding a 4-digit value
    (`8871` → `08871` had a valid state prefix but a non-existent county), so a
    `FORM_TYPE` column stops being `geographic`.

* **Tag sets.** New `is_tags()` detector + `as_tags` verb wire the
  `categorical/multiselect/tags` leaf, so a flat delimited set (`"a|b|c"`,
  `"Volunteer;Donor;Board"` — a list column collapsed to a string) is
  recognized and normalized to a `;`-joined form, instead of going unrecognized.

* Fixes from datagoodr's `dplyr::starwars` detection-quality report:
  - **Named colors.** New `is_color_name()` detector + a curated color-word
    lexicon (CSS/X11 + descriptive and hair/eye terms) and a `text/color/color_name`
    leaf, so `hair_color` / `eye_color` columns resolve to a color type instead
    of leaking to `geographic` (the color words "brown", "auburn", "orange" are
    also US place names). The leaf joins the verifier's always-on set.
    `is_color_name()` also accepts all-color **compounds** (`"brown, grey"`,
    `"blue-gray"`, `"dark brown"`) and rejects fillers (`"none"`, `"unknown"`),
    so real `hair_color` / `eye_color` columns (which mix single and compound
    values) resolve to the color type instead of staying on `geographic`.
  - **Stabilizing to the default format is reachable.** The canonical value a
    recipe produces already *is* the type's default written form, so a write
    edge to each row's `desired_default_format` is generated by identity — a
    date renders to `yyyymmdd`, a measurement/number to `numeric`, a year to
    `yyyy`, instead of "no path". (Generalizes the earlier `write_numeric`;
    fixes the baseball `birthDate` / `debut` dates reported by datagoodr.) Unit
    *menus* (e.g. `unit-specific (kg;;m;;C;;L)`) collapse to no unit for planning.

* **v7 ontology + transform API.** The leaf gains two orthogonal axes —
  `format_style` (how a value is written) and `unit_type` (renamed from
  `dd_data_unit`; what it means) — plus `desired_default_format`. Additive:
  `format_label` is kept (derived) so the router and verifier are unchanged.
  A transform planner (`fx_format()`, `fx_plan_transform()`, `fx_transformable()`,
  `fx_apply_plan()`, `fx_transforms()`) models stabilization as a path search over
  a `read_`/`write_`/`convert_` registry generated from the ontology recipes;
  `fx_stabilize(..., target_format=)` renders to a chosen style (with
  `rendered` / `target_reachable`), and `$route` now reports `format_style`.
* **Disambiguator.** The ontology carries a `disambiguator` column declaring the
  tie-break for every path collision, and `fx_validate_ontology()` fails on an
  *undeclared* one. `geographic` (a categorical grouping vs. an identifier key)
  declares `cardinality:repeating` / `cardinality:unique`; the colliding
  `unknown/.../mixed` leaf is renamed `heterogeneous` so only the boolean
  `mixed` keeps the name. The rule is **wired live**: `guess_data_type()` passes
  the column's uniqueness ratio to the verifier, which applies it when two
  confirmed candidates collide — so a repeating FIPS column routes to the
  categorical `geographic` grouping and a unique-per-row FIPS column to the
  `identifier` key. A new FIPS-validating `as_fips` recipe also fixes an upstream
  gap (a county FIPS column used to fall through to `count`; a random 5-digit
  number is now correctly rejected as geographic). A `collision_group` column
  extends this to *cross-type* collisions — a column of city names is a
  geographic grouping when the values repeat and a `text/name/place` column when
  they are mostly unique — using the same cardinality rule across leaves that
  share no `semantic_type`.
* **Detectors wired (test-case-backed):** `day_of_week` and `month_of_year`
  gain selective `as_dow` / `as_moy` recipes; `first_name`, `quarter`, and
  `domain` had their stale `implemented` flag reconciled; and a new
  `is_currency_amount()` (symbol-required, so bare numbers are not mistaken for
  currency) makes the `as_usd` recipe selective, wiring `usd`; `place` gets a
  selective `lookup:place` recipe, `min_max` range is confirmed via a tightened
  `as_range`, and `point` / `polygon` are wired via a keyword-gated `as_wkt`
  (the `geometry` family joins the verifier's always-on set, since the router is
  too sparse to shortlist it). New `is_version()` detector. 36 → 46 of 96
  variants implemented. Fixes: the transform-DSL arg parser dropped a trailing
  `]` on `verb[arg]`; `as_range` no longer claims nested arrays as ranges.

* Recipe/helper fixes from the datagoodr reintegration review:
  - `as_yyyy()` and the `as_yyyy` stabilize verb now strip a fiscal-year prefix
    (`"FY2019"` → `"2019"`) instead of returning the raw string / `NA`.
  - `as_EIN()` and the `as_ein` verb now emit the canonical `"NN-NNNNNNN"` form
    and restore a leading zero lost to numeric coercion (`"12345678"` →
    `"01-2345678"`).
  - Removed the stale duplicate `data-types/research_data_type_ontology_v6.csv`;
    `fx_ontology()` reads `inst/extdata/` (the 96-row authority).

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
