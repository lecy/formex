# formex — development status, gaps & the test-data library

> Status snapshot, 2026-10-25. A companion to the user-facing *Type Atlas*
> vignette (`vignettes/formex-type-atlas.Rmd`). The Atlas describes what each
> type *is*; this note records what is *built*, what is *not*, and what the
> detectors were tested against. Numbers are from the shipped ontology
> (`fx_ontology()`, 96 variants) and the dev test library
> (`dev/feature_matrix_all.rds`, 4,036 columns). The `dev/` tree is local
> scaffolding and is not shipped or version-controlled, so the library figures
> are a point-in-time measurement, not a build artifact.

## 1. Where the engine stands

The two public verbs are both wired and pass the suite (121 tests, 0 failures):

- `guess_data_type()` — two-stage router → verifier, returning the `$route`
  record plus the legacy fields.
- `fx_stabilize()` — the transform executor (`fx_transform()` + a verb library)
  that the original integration plan listed as the critical missing path. It is
  now built; the DSL parser and ~31 verbs run against the ontology recipes.

Still per the plan and not formex's to build: the `datagoodr` governance-file
schema and the actual extraction of the moved files out of `datagoodr` (see
`INTEGRATION-NOTES.md`).

## 2. Implementation coverage (what has a working detector)

Of **97** ontology variants, **48 (49%) are marked `implemented = "yes"`** — a
wired, exercised detector. The rest are declared recipes (data_format /
transform / stable_format / import_rule are populated) waiting on a detector,
verb, or gazetteer.

> **v7 session update.** Coverage rose 36 → 46 by wiring test-backed,
> foil-selective detectors (`data-raw/wire_detectors_v7.R`): `day_of_week` /
> `month_of_year` (new `as_dow` / `as_moy`), `first_name`, `quarter`, `domain`,
> `usd` (new `is_currency_amount` — symbol-required), `place` (`lookup:place`),
> `min_max` range, and `point` / `polygon` (`is_wkt_geometry`, keyword-gated).
> Key finding worth carrying forward: a selective recipe is necessary but **not
> sufficient** to route — the learned router never shortlists very rare `mask`
> leaves (`array`, `version`, `reporting_period` confirm in isolation but never
> reach the verifier), so they stay unimplemented until either the router has
> training cases or they join the verifier's always-on set (as the `geometry`
> family now does). Two verb bugs were fixed along the way: the DSL arg parser
> left a trailing `]` on `verb[arg]`, and `as_range` was loose enough to claim
> nested arrays as ranges.
>
> **Later in the session:** the **disambiguator** landed (a `disambiguator` /
> `collision_group` column + a cardinality tie-break wired into the verifier,
> resolving the `geographic` grouping-vs-key and the cross-type place↔geographic
> collisions; `fx_validate_ontology()` fails on an undeclared collision).
> `fx_stabilize()` gained a **`conversion_log`** and a warning when present
> values are dropped to `NA`, so silent data loss is surfaced. From datagoodr's
> `dplyr::starwars` report: a named-color leaf (`text/color/color_name` +
> `is_color_name()`) fixes color words leaking to `geographic`, and a
> `write_numeric` edge lets plain measurements stabilize to numeric; and a
> `tags` detector (`is_tags`) wires `categorical/multiselect/tags` for delimited
> list columns. Coverage is now **48/97**; 92 detectors; 121 tests.

### By data type

| data type | implemented / total |
|---|---|
| identifier | 9 / 10 |
| temporal | 6 / 12 |
| text | 14 / 24 |
| categorical | 7 / 13 |
| **number** | **0 / 23** |
| **boolean** | **0 / 5** |
| **structured** | **0 / 6** |
| unknown | 0 / 3 (by design — the residual bucket) |

### By detection mechanism

| `match_kind` | implemented / total | reading |
|---|---|---|
| genome | 3 / 3 | complete — dates, timestamps, clock |
| mask+lexicon | 6 / 7 | strong — addresses, FIPS, state |
| mask | 20 / 48 | half — IDs/web/color/contact done; coords, ranges, geometry, booleans open |
| lexicon | 4 / 10 | person/place/country/handle recipes still open |
| **shape** | **0 / 12** | the whole `number/quantity` + `portion` block — not value-typable by subtype |
| none | 3 / 16 | `none` is "not value-detectable"; these need header/codebook |

## 3. Unimplemented detectors, grouped

Highest leverage first (the mechanism tells you whether the work is a detector,
a verb, or a reference list).

**`number` — the biggest gap (0 of 23).** Every quantity, portion, currency,
range and coordinate variant is unimplemented.
- `shape` (not subtype-detectable from values; need the header): `measurement`,
  `count`, `rate`, `ratio`, `duration`, `score`, `index`, `rank`,
  `probability`, `odds`, `percent`, `percentile`.
- `mask` (detector + verb is real work): `currency/{balance,usd,euro}`,
  `range/{comma_pair,to_range,confidence_interval}`,
  `coordinate/{lat_lon dms, lat_lon iso6709, lon_lat, lat, lon}`.

**`boolean` (0 of 5).** `is_boolean()` exists and recognizes the two-state
vocabulary, but no `binary` variant is marked implemented and the class
(`indicator` / `presence` / `status` / `response` / `mixed`) needs the header.
Worth reconciling: the detector is shipped but the ontology rows say otherwise.

**`structured` (0 of 6).** Detectors exist (`is_json`, `is_wkt_geometry`,
`is_geojson`, `is_wkb`) but `collection/{list,array}`, `record/{object,
key_value}` and `geometry/{point,polygon}` are not wired; recipes pass through
as literal text.

**`temporal` (6 of 12).** Open: `period/{quarter, reporting_period}`,
`phase/{hour_of_day, day_of_week, month_of_year, week_of_year}`.

**`text` (14 of 24).** Open: `name/{first_name, last_name, full_name, place,
handle}` (lexicon-bound), `text/{label, title, long, serialized}` (`none`),
`web/domain`.

**`categorical` (7 of 13).** Open: `scale/{likert, rating, ranking,
grade_level}`, `multiselect/tags`, `mutually_exclusive/missingness_reason` — all
`none`, i.e. codebook-gated.

**`identifier` (9 of 10).** Only `id/version` remains.

## 4. Repo hygiene gaps

- ~~**Ontology drift.**~~ Resolved: the stale `data-types/…_v6.csv` duplicate
  was removed; `fx_ontology()` reads `inst/extdata/` (the authority). (Older
  design snapshots `…_v2/v3/v4.csv` remain for history.)
- ~~**No CI.**~~ Resolved: a standard r-lib **R-CMD-check** workflow
  (`.github/workflows/R-CMD-check.yaml`) builds the package, runs the suite, and
  builds the vignettes on push / PR to `main`.
- **Version** is still `0.0.0.9000`; nothing published.
- The benign `NAs introduced by coercion to integer range` warning fires ~18×
  across the suite (numeric-coercion paths) — cosmetic, worth bounding.

## 5. The test-data library

The detectors are measured against a **unified library of 4,036 real and
synthetic columns**, one row per column, assembled from three sources and
crosswalked to the formex ontology.

### 5.1 Columns ingested, by source

| source | columns | nature |
|---|---|---|
| **Sherlock / VizNet** | 3,423 | real columns sampled from the ~137K-column VizNet test split; 78-type Sherlock label vocabulary. Labels derive from headers, so they are noisier — deliberately, as hard negatives |
| **synthetic_temporal** | 436 | generated columns across the temporal leaves, exact ground truth, an easy + mutated-hard mix, to give the router the dense, balanced temporal neighbourhood the wild corpora lack |
| **GitTables** | 177 | real columns with independent headers (so usable for the name-side evaluation too) |
| **total** | **4,036** | |

By formex data type the library leans heavily text/categorical/number:

```
text 1339 · categorical 1283 · number 667 · temporal 553 · identifier 149 · unknown 38 · structured 5 · boolean 2
```

### 5.2 How they were standardized into one library

A corpus-agnostic banking core (`dev/bank_core.R`) turns every source into the
same shape, so everything downstream is identical regardless of origin:

1. **Record.** Each source column becomes a record
   `list(values, label, table_id, header)` via a per-corpus **adapter**
   (GitTables CSV, Sherlock parquet, the temporal generator). Heterogeneous
   value encodings — stringified Python lists, Arrow list-columns, materialized
   vectors — are parsed to a clean character vector; headers are snake-cased.
2. **Crosswalk / resolve.** A **resolver** maps the source's own label
   vocabulary to a formex ontology coordinate through a `*-crosswalk-v4.csv`
   whose `v4_type / v4_class / v4_subclass` columns are the v6 path, emitting a
   `semantic_type_id` + `variant_id` against the live ontology.
3. **Triage & bank.** `fx_triage_field()` → `fx_make_test_case()` writes a
   uniform schema-v2 JSON test case per column, with an exclusion log for
   rejects.
4. **Diversity sampling (Sherlock).** 137K columns is too many and mostly
   redundant, so cases are chosen by farthest-point selection over
   `fx_type_signature()` distance (capped per type) rather than a random draw —
   maximizing shape diversity and surfacing hard negatives.
5. **Feature matrix.** `dev/build_feature_matrix.R` assembles the labeled
   substrate the router/verifier train on: one row per banked column, the
   value-only v2 feature profile (~471 features) plus public-domain gazetteer
   membership features, joined to the label axes (`data_type` → `variant_id`).
   Result: `feature_matrix_all.rds`, 4,036 × 491.

### 5.3 Test cases per formex variant (after crosswalk)

Crosswalking to the ontology, **53 of 96 variants carry at least one test case;
43 carry none.** Among variants that have cases: median **24**, mean **73**,
max **611**. The distribution is very uneven:

| cases per variant | 1 | 2–5 | 6–10 | 11–25 | 26–50 | 51–100 | 100+ |
|---|---|---|---|---|---|---|---|
| variants | 6 | 9 | 4 | 11 | 5 | 6 | 12 |

Best-covered variants:

| variant | cases | path |
|---|---|---|
| `n0044-f01` | 611 | categorical / unordered |
| `n0046-f01` | 459 | categorical / iso_country |
| `n0028-f01` | 371 | text / organization |
| `n0027-f01` | 359 | text / first_name |
| `n0001-f01` | 223 | number / measurement |
| `n0059-f01` | 182 | temporal / calendar |
| `n0002-f01` | 148 | number / count |
| `n0073-f01` | 77 | identifier / ein |

**The coverage and the implementation status do not line up**, which is the main
testing gap:

- **18 implemented variants have zero test cases** — detectors with no
  independent column in the library to confirm them against.
- **35 variants have test cases but are not implemented** — labeled data waiting
  for a detector/verb (much of it the `number/quantity` and `shape` block, which
  the crosswalk can label but the engine cannot yet type by value).
- Whole families are thin or empty: `number/coordinate` (3 cases),
  `structured/geometry` (1), `boolean/binary` (2), `text/contact` (2). Any
  accuracy claim there rests on a handful of columns.

### 5.4 Caveats

- The library is banked against an earlier ontology snapshot (the build scripts
  reference a 92–94-row ontology); the crosswalk targets v6 *paths*, so labels
  resolve, but the 96-row shipped ontology has moved since.
- `dev/stabilize_rate.R` — the source of the per-mechanism confirm rates — reads
  only the Sherlock + synthetic-temporal banks (`feature_matrix.rds`, 3,859
  columns), not GitTables, and counts `none` / open-set types as not-stabilized.
- Sherlock labels come from headers, so a slice of the "truth" is itself noisy;
  this is intentional (hard negatives) but caps the achievable top-1.

## 6. Forward plan (2026-10-29 addendum)

A roadmap for the two open fronts — finishing the detector set and improving the
router — plus four design decisions that came out of looking hard at the shipped
model (`inst/extdata/router_xgb.rds`, 3,853 cases × 441 features, 47 classes, OOF
top-1 0.771 / top-5 0.946 / top-8 0.965).

### 6.1 Detector implementation roadmap

The remaining unimplemented variants split by **mechanism**, and the mechanism
dictates the work. Sequenced by leverage:

**Phase A — `mask` detectors (value-detectable, highest routable payoff).**
These are real detector+verb work but the values carry the signal, so they both
confirm *and* can be learned-routed once cases exist.
- `number/currency/{balance,usd,euro}` — `is_currency_amount` (symbol-required)
  landed for `usd`; generalize to a currency+amount mask with a `unit_type`
  (USD/EUR/…) and the `write_*` renderer.
- `number/range/{comma_pair,to_range,confidence_interval}` — `min_max` done;
  add the CI form and the `lo to hi` style.
- `number/coordinate/{lat_lon dms, iso6709, lon_lat, lat, lon}` — net-new mask
  detectors; pair with a decimal-degree canonicalizer.
- `structured/geometry/{point,polygon}` and `structured/collection|record` —
  the detectors already exist (`is_wkt_geometry`, `is_geojson`, `is_wkb`,
  `is_json`); the work is wiring the ontology rows `implemented = yes` and giving
  them a pass-through/parse recipe. Geometry is already in the verifier's
  **always-on** set, so it routes without the model (see §6.6).
- **`boolean/binary` reconciliation (quick win).** `is_boolean()` is shipped and
  works; the rows say unimplemented. Wire + mark; the *class*
  (indicator/presence/status/response) is header-gated and belongs in Phase C.

> **Carry-forward rule from the v7 session:** a selective recipe is *necessary
> but not sufficient* to route. A new `mask` leaf that confirms in isolation
> (`array`, `version`, `reporting_period`) is still invisible to the learned
> router until it has training cases or joins the always-on set. **Every Phase-A
> detector ships with banked cases, or it does not count as routable** (§6.6).

**Phase B — `lexicon` detectors (need a reference list).**
`text/name/{last_name, full_name, place, handle}`. `first_name` and `place`
landed; `last_name`/`full_name` reuse the surname gazetteer, `handle` needs a
small pattern+lexicon. Gated only by shippable, licence-clean lists.

**Phase C — `shape` / `none` types are NOT a detector problem.**
The whole `number/quantity` block (`measurement`, `count`, `rate`, `ratio`,
`duration`, `score`, `index`, `rank`, `probability`, `percent`, `percentile`),
the boolean/categorical *classes*, and `text/{label,title,long}` are **not
value-typable by subtype** — a column of doubles cannot tell you it is a *rate*
rather than a *ratio*. These need the column **header/codebook**, i.e. the
name-side (`nm_*`) feature path, which is currently dark (§6.4). Phase C is
therefore a *router/arbiter* task (turn the name features on and fuse them), not
a detector task. Do not ship value-only detectors for these; they will only
manufacture false leaves.

### 6.2 Router improvement plan

1. **Parity guard. ✅ Landed 2026-10-29.** The artifact stamps
   `extractor_version = 2.0` but nothing asserted the *live* `fx_extract_features`
   still matched it. `.fx_router_artifact()` now checks at load time: if
   `FEATURE_EXTRACTOR_VERSION != art$extractor_version` (or the artifact is
   unstamped), it drops the learned router and falls back to signature with a
   one-time warning. This was the one failure mode that silently returned
   garbage (the original "scored at chance" bug).
2. **Un-blind the dropped feature classes (§6.4).** Bank cases — synthetic where
   the type is rare-but-regular (the `bank_temporal` recipe) — for the types the
   corpus currently has **zero** examples of: SSN, EIN, UUID, IPv4, ZIP+4,
   YYYYMM, hex hashes, JSON, DMS coordinates, international phone, scientific
   notation. This simultaneously (a) adds the classes the model can predict and
   (b) gives the `rx_*` features variance so they stop being dropped.
3. **Name-side fusion (unlocks Phase C).** Bank columns *with headers*, feed the
   name to the extractor so the 17 `nm_*` features compute, and train either a
   name-aware model or a late-fusion arbiter (value-router ⊕ name-signal). This
   is the only route to the header-gated types.
4. **Rebalance.** The corpus leans text/categorical/number; `top-1 by
   match_kind` already shows `mask` (0.964) trailing `genome`/`lexicon` (~1.0).
   Stratify or class-weight so thin types are not drowned.
5. **Calibrate the depth gates.** The learned router's top-1 probability sets
   truncation depth directly (`≥0.50 → 3`, `≥0.25 → 1`). Plot a reliability curve
   and set those cut-points from calibration rather than by hand.
6. **CI + non-regression gate.** Wire `fx_benchmark()` + `fx_benchmark_compare()`
   into the retrain step; a new artifact ships only if it does not regress the
   shipped one on any level or the per-`match_kind` top-k recall.

### 6.3 Should we sunset the legacy flat detector path?

**Verdict: deprecate, don't delete — and demote it now.** It is not
synergistic with the router path; it is a parallel, older contract.

Reasons it still earns its place *today*:
- **Backward contract.** `$guess` / `$ontology` / `$candidates` and the flat
  coordinate axes (`data_type / data_subtype / data_class / data_format`) are
  consumed by `guess_column()` and five test suites; the flat `data_format` axis
  is not 1:1 with the v6/v7 `format_style`/`unit_type` axes.
- **Independent fallback.** It needs neither xgboost nor the ontology CSV — pure
  predicate scoring. When `.fx_route_verify()` errors (it is wrapped in
  `tryCatch → NULL`), the legacy fields still answer.
- **The detectors are shared, not duplicated.** The `is_*` predicates are reused
  by the verifier (recipe = detector + transform), so keeping the detectors costs
  nothing; only the *flat scoring + flat ontology crosswalk* is redundant.

Reasons to retire it on a schedule:
- **Two ontologies to maintain.** `R/00-data-type-ontology.R` is a hand-kept flat
  crosswalk that can drift from the v6/v7 ontology — a standing correctness risk.
- **Cost.** `score_data_type()` runs **all 88 detectors on every call** — exactly
  the O(all-detectors) scan the router was built to avoid — yet it runs
  unconditionally because `route = TRUE` is the default.

**Plan:** (1) **✅ Landed 2026-10-29** — `guess_data_type(..., legacy = FALSE)`
skips the flat scan and returns only the `$route` record (legacy fields present
but empty); measured at ~13% of the full per-call runtime on a typical column,
since it no longer scores all 88 detectors. (2) document `$guess`/`$ontology` as
deprecated-but-supported; (3) remove only after datagoodr and any flat-axis
consumers migrate to `$route`, and after v7's `format_style`/`unit_type` fully
subsume the flat `data_format` axis. Target: drop in the release that removes
`format_label`, alongside the router retrain that release already forces (§6.6).

### 6.4 Feature hygiene: why 36 of 477 features drop out

Measured by reproducing `train_router.R`'s variance filter over the 3,859
training columns (`data-raw/` diagnostic). **The features are not defective — the
drop is corpus-driven**, and it splits three ways:

| bucket | n | examples | reading |
|---|---|---|---|
| **all-NA (never computes)** | 17 | `nm_amt`, `nm_date`, `nm_person`, `nm_id`, … (16 `nm_*`) + `chk_ein_prefix_rate` | the **name-side block is gated off** — training is value-only, no header is fed, so these are structurally absent, not broken. They light up the moment §6.2(3) feeds headers. |
| **constant everywhere (sd 0)** | 18 | `rx_ssn`, `rx_ein`, `rx_uuid`, `rx_ipv4`, `rx_zip9`, `rx_yyyymm`, `rx_hexhash`, `rx_jsonfrag`, `rx_latlon_dms`, `rx_phone_intl`, `rx_sci_not`; `in_is_numeric/date/factor/logical`, `is_constant`, `pct_missing` | split in two (below) |
| **constant where present (gated, sd 0)** | 1 | `range_epoch_ms` (computes on 18.8% of cols, all 0) | near-degenerate on this corpus |

So the answer to "universal or selective?" is **both, and the distinction is the
useful part**:

- The `in_is_*` flags, `is_constant`, and `pct_missing` are **structurally
  constant** in the banked pipeline: `recon()` always yields a *character* vector
  with no NAs and >1 value, so input-class / missingness / degeneracy flags can
  never vary. These are genuinely uninformative *here* (they would vary on raw
  typed input) — harmless to drop.
- The `rx_*` regex-hit rates are constant **at exactly 0** — confirmed over the
  full 4,036-column matrix, zero non-zero columns. They are not broken; **the
  corpus simply contains no SSN / EIN / UUID / IPv4 / ZIP+4 / YYYYMM / hex-hash /
  JSON / DMS-coordinate / intl-phone / scientific-notation columns**. A rate that
  is 0 for every training column carries no signal and is dropped.

**The payoff:** the dropped-`rx_*` set is a *free blind-spot diagnostic*. It
enumerates, independently of the label crosswalk, exactly the types the learned
router has no training signal for — and it corroborates §5.3's "18 implemented
variants have zero test cases." These are the same types §6.2(2) targets, and
they map straight onto the `number` / `structured` / thin-`identifier` gaps in
§3. Recommendation: add an assertion to the retrain script that any `rx_*`
feature dropped for zero variance **names the type to bank next**, so the gap is
surfaced at train time rather than discovered by inspection.

### 6.5 Flagging underperforming detectors (difficulty-aware)

**Shipped.** `fx_coverage_gaps()` formerly used a **flat** gate
(`max_accuracy = 0.5`, `min_support = 3`). The objection was correct: a universal
threshold conflates three different things — intrinsic difficulty, thin/noisy
support, and a genuine detector bug. The flat gate is replaced with four signals
and **two action buckets**, so each flag points at a fix:

1. **Per-`match_kind` target, not a single number.** Achievable precision is a
   function of mechanism: `genome`/`lexicon`/`mask+lexicon` types can reach
   ~0.95; `shape`/`none` types are header-gated and should be **excluded from
   value accuracy entirely**, not scored at 0. Set the target by `match_kind`.
2. **Baseline-relative, not absolute.** Flag a type where the **learned router
   underperforms the signature router** (run both via `router=`). A type hard for
   *everyone* is difficulty, not a bug; a type where learned < model-free floor is
   a real regression. (`fx_benchmark_compare()` already computes these deltas.)
3. **Stress-delta (robustness).** Use `fx_stress_grid()`: flag types whose
   accuracy **collapses under mild perturbation** (low whitespace / case /
   contamination) relative to their own clean-tier score. Brittleness to a space
   or a stray uppercase is a detector bug regardless of absolute accuracy, and
   `fx_contamination_curve()` already measures the shape.
4. **Support-aware confidence.** Put a Wilson interval on the accuracy estimate;
   only flag "low-accuracy" when the interval's **upper bound** is below target,
   so thin-support types are not flagged on noise.

**Two buckets, two fixes:** `needs-cases` (thin support, **or absent from the
corpus** → bank/generate data, §6.2(2)) vs `needs-detector-work` (adequate
support but accuracy upper-bounded below target, losing to the signature
baseline, or stress-brittle → fix the predicate/recipe); header-gated
`shape`/`none` types with adequate support are `excluded`, the rest `ok`.
`fx_coverage_gaps()` gained a `target` argument (default by `match_kind` via
`.FX_COVERAGE_TARGETS`), optional `baseline=` and `stress=` run arguments,
`wilson_upper` / `baseline_delta` / `stress_drop` columns, and emits a `bucket`
label in place of the old `"ok" / "low-accuracy" / "low-support"` flag. With
`include_absent = TRUE` (the default) it also walks the full ontology and emits a
`support == 0` `needs-cases` row for every **live** variant that never appears in
the corpus — the blind spots the per-case signals cannot see.

*Not yet wired:* tying the dropped-`rx_*` feature set into `needs-cases`. That
set is enumerated at retrain time (§6.4), not persisted as a loadable object, so
there is no programmatic handle for `fx_coverage_gaps()` to read yet; wiring it
in waits on the retrain script banking the dropped-`rx_*` names as an artifact.

### 6.6 Router refresh: cadence & triggers

The learned router predicts over a **fixed 47-class set** (`art$levels`).
Inference maps predicted ids to ontology rows by `match()`, so the framework
**degrades gracefully, it does not break**: an ontology id not in `art$levels` is
simply never shortlisted; an `art$levels` id no longer in the ontology is
dropped. The question is therefore not "does X break the router" but "does X
leave the router blind to something it should route."

**MUST retrain (correctness):**
- **Any `fx_extract_features` change** — a feature added, removed, reordered, or
  recomputed. The artifact bakes in feature names, column order, and median
  imputations; a mismatch is silent train/serve skew. Bump
  `FEATURE_EXTRACTOR_VERSION`, retrain, and rely on the §6.2(1) parity guard in
  the interim.
- **Removal of `format_label`** in v7 (the router trains on it; already the
  deferred retrain in `ONTOLOGY-V7-PLAN.md` §5).

**SHOULD retrain (coverage):**
- A **new routable `semantic_type_id`** added to the ontology — to add it as a
  predictable class. (Interim: add high-precision types to the verifier's
  **always-on** set, as geometry/email/color-name already are — this makes them
  routable with *no* retrain.)
- **New or expanded training cases** for an under-covered type, especially the
  §6.4 zero-example types — to lift its top-k recall.
- A **benchmark regression** where `fx_benchmark_compare()` shows learned losing
  to signature on a level or `match_kind`.

**NO retrain needed:**
- A new detector/recipe for an **existing** class — the verifier picks it up and
  the router already shortlists the class.
- **Deprecating** a row (ids are never renumbered/reused; `match()` handles it).
- Pure `fx_stabilize` verb/transform additions (they are not router inputs).

**Cadence:** there is no fixed schedule, nor should there be — retrain is
**event-driven** by the triggers above, gated by the §6.2(6) non-regression
check. The one standing recommendation is the parity guard, so that the
"correctness" triggers can never fail silently between retrains.

## 6. Benchmark-driven detector priorities (2026-10-29)

> The benchmark is **still in development** — not yet frozen for published
> reference. The frozen set now covers **all 97 ontology variants** (was 51):
> `data-raw/scaffold_gap_cases.R` banks one format-faithful case per
> previously-uncovered variant into `dev/bank_v2` (values from the
> `data-raw/datatypes/*.R` detector fixtures, or a seeded generator where no
> fixture exists), and `build_benchmark.R` now bundles the full set in
> `inst/extdata/benchmark_full.rds`. These scaffolds are
> `method = "scaffold_synthetic"`, `confidence = "low"` — regression anchors
> and a gap probe, **not** gold-vetted corpus columns; confirm/relabel before
> any published accuracy claim.

Running `fx_benchmark()` over the newly-covered variants splits cleanly into
two very different kinds of failure. **The split, not the headline number, is
the finding** — it says whether the work is router tuning or new detector code.

### 6.1 P0 — router recall: 11 *implemented* detectors are dark

These variants are `implemented = "yes"` with a selective recipe, yet the
router never routes to them (prediction is `<none>` or a wrong neighbour). No
new detector code is needed — the fix is in the shortlist/router. This is the
single highest-ROI item and confirms the §2 note that *a selective recipe is
necessary but not sufficient to route; the learned router never shortlists very
rare `mask` leaves.*

| variant | path | predicted instead |
|---|---|---|
| `n0040-f01` | text/color/**hex** | `<none>` |
| `n0041-f01` | text/color/**rgb** | measurement |
| `n0042-f01` | text/color/**hsl** | measurement |
| `n0043-f01` | text/color/**cmyk** | `<none>` |
| `n0036-f01` | text/web/**ip** | `<none>` |
| `n0037-f01` | text/web/**mac** | `<none>` |
| `n0039-f01` | text/contact/**phone** | `<none>` |
| `n0032-f01` | text/postal/**po_box** | unordered |
| `n0064-f01` | temporal/period/**month** | calendar |
| `n0022-f01` | text/text/**literal** | `<none>` |
| `n0073-f05` | identifier/id/**administrative (issn)** | **date_range** |

**Action.** Add confirmable `mask` leaves to the verifier's always-on set (as
the `geometry` family already is) or seed the learned router with these cases so
it shortlists them. `issn → date_range` is a genuine confusability bug
(`NNNN-NNNN` collides with a date range) — give it a `hard_negative` /
`disambiguator` entry.

### 6.2 P0 — the boolean data type is 0%

`presence` / `status` / `response` / `mixed` all misroute (to `unordered` or
`<none>`); `acc_data_type` for `boolean` is **0.00** on the benchmark. `is_boolean()`
exists but no `binary` variant is wired, so an entire data type is invisible.
Wire the boolean verifier into the always-on set and reconcile the ontology
`implemented` flags.

### 6.3 P1 — number masks (real detector + verb work)

`implemented = "no"`, `mask`-detectable from values, so each needs a detector
and a stabilize verb: `balance`, `euro` (currency), `min_max`,
`confidence_interval` (range), `lat`, `lat_lon`, `lon_lat` (coordinate). They
misroute to `measurement` / `min_max` / `rank`. Highest value in the `number`
block because the surface form *is* typable (unlike the `shape` subtypes below).

### 6.4 P2 — shape numerics and codebook-gated types (fail safe or need header)

- `number/shape`: `probability`, `odds`, `percentile` land **graceful** (correct
  `data_type`, no committed subtype) — they fail safely and are low urgency;
  `rate` misroutes to `measurement`. None are subtype-typable from values alone.
- `categorical/none`: `likert`, `missingness_reason` and `text/text/serialized`
  need a codebook/header; low yield from values.
- `temporal/phase`: `hour_of_day`, `week_of_year` are bare small integers,
  genuinely ambiguous with `number` without a header.
- `structured` non-geometry: `array`, `object`, `key_value` route to
  `<none>` / `tags`; `is_json` / `is_wkb` exist but are not wired for these.
  (`point` / `polygon` already **hit** — now regression-covered.)

### 6.5 Already correct (now regression-anchored)

Nine previously-untested variants **hit** on the first benchmark and now have a
guard: `geographic` (×3), `administrative` isbn/doi/orcid (×3), `point`,
`polygon`, `color_name`.

**Housekeeping.** The ontology `implemented` flag is stale for `person`
(`n0027-f02/f03` are marked `no` but the benchmark hits them) — reconcile with
§2's boolean note in the same pass.

**Reproduce:** `Rscript data-raw/scaffold_gap_cases.R && Rscript
data-raw/build_benchmark.R`, then `fx_benchmark(fx_benchmark_data("full"))` and
`fx_coverage_gaps()`.

### 6.6 Format-sliced depth for the P0 types (2026-10-29)

The gap scaffold gave each P0 variant exactly **one** canonical case (n=1,
synthetic, `confidence=low`) — enough to measure *coverage* but not *format
drift*, the real failure surface. `data-raw/scaffold_format_slices.R` now banks
**several cases per P0 variant, one per distinct surface shape** (positive,
single-shape columns of ~34 rows; values sliced from the `data-raw/datatypes/*.R`
fixtures by regex, or seeded-generated where the fixtures lack a shape). This
adds **50 cases** across the 15 P0 variants (full set 867 → **917**; every P0
variant now carries 3–6 cases), labelled `method="scaffold_format_slice"`,
`corpus="scaffold_fmt"`, `confidence="low"`, with the exact shape recorded in
`label.format_label` / `original_label` / `notes`. Shapes added:

- **hex** `#RRGGBB`, `#RGB`, bare `RRGGBB`, `0xRRGGBB`
- **rgb** `r,g,b`, spaced `r, g, b`, functional `rgb(r,g,b)`
- **hsl** `h, s%, l%`, functional `hsl(…)`; **cmyk** fractional `c,m,y,k`, functional `cmyk(…)`
- **ip** IPv4 dotted, IPv6 full, IPv6 compressed (`::`)
- **mac** colon, hyphen, Cisco-dotted; **phone** NANP dashed / parens / dotted, E.164 `+1-…`, international `+CC …`
- **po_box** `PO BOX n` / `P.O. Box n` / `POB n` / `Box n`
- **month** `yyyymm` / `Mon YYYY` / `YYYY-MM` / full name
- **literal** 3 deliberately heterogeneous mixed-content columns
- **issn** `NNNN-NNNN` / check-digit `NNNN-NNNX` / `ISSN `-prefixed
- **boolean** presence (x·blank / 1·blank / present·absent), status (active·inactive / enabled·disabled / on·off / open·closed), response (yes·no / Y·N / true·false / T·F / 1·0), mixed (2 multi-encoding columns)

**Per-format finding: the P0 failures are systemic, not shape-specific.** The
router misroutes on **every** shape of nearly every P0 variant — it never
reaches these leaves at all, so format drift is not yet the differentiator (it
will become one once §6.1/§6.2 land the routing). Two exceptions are the
actionable signal:

- **hex** `#RRGGBB` lands **graceful** (recognized as `text`, subtype dropped),
  while its drift variants (`#RGB`, bare `RRGGBB`, `0xRRGGBB`) all **misroute** —
  the canonical hash-6 form is the only shape the pipeline half-recognizes.
- **issn** **hits** only when the literal `ISSN ` prefix is present; bare
  `NNNN-NNNN` **misroutes** (the `date_range` collision from §6.1) and the
  check-digit `NNNN-NNNX` form lands **graceful**. The prefix token *is* the
  disambiguator — direct evidence for the §6.1 `hard_negative`/`disambiguator`
  action.
- **boolean** is **0%** across all 20 cases (every shape, every subtype),
  re-confirming §6.2.

These cases are regression anchors for the P0 work: when a routing fix lands,
the per-format `hit/graceful/misroute` split (group `fx_benchmark()` output by
`format_label`) shows *which* shapes it recovered, not just a single number.
This is recommendation #1 of the benchmark review (format depth); the
hard-negative/confusability bank is a separate follow-up.

**Reproduce:** `Rscript data-raw/scaffold_format_slices.R && Rscript
data-raw/build_benchmark.R`, then `fx_benchmark(fx_benchmark_data("full"))` and
join `format_label` back by `case_id` for the per-shape split.
