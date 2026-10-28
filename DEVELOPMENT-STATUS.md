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
