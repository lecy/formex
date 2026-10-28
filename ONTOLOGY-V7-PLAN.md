# formex v7 plan — `read_*`/`write_*` verbs and a two-axis leaf

> Scope + design note, 2026-10-26. Responds to
> `datagoodr/dev/formex-devnote-schema-simplification.md` (asks 2, 3, 4) and to
> the proposal to split `format_label` into a unit axis and a style axis. The
> quick fixes from that note (the `as_yyyy`/`as_ein` recipe bugs, the stale CSV)
> are already landed; this note is the larger, not-yet-implemented work.

## 1. Three operations, not one

Today one verb per ontology row (`raw_to_stable_transform = {{ as_mmddyyyy }}`)
bakes the parse *and* the canonical output into a single step, so formex can only
ever emit the canonical/ISO form. Decompose it into three composable pieces:

| verb | direction | example | notes |
|---|---|---|---|
| `read_<style>` | written form → canonical internal value | `read_mmddyyyy("03/15/2019")` → a Date | this is today's `as_*`, the parse half |
| `write_<style>` | canonical value → a chosen written form | `write_yyyymmdd(date)` → `"2019-03-15"` | the new half |
| `convert_<unit→unit>` | canonical value in one unit → another unit | `convert_C_F(20)` → `68` | changes meaning, not rendering |

A full stabilizer composes them:

```
{{ read_mmddyyyy :: write_yyyymmdd }}                 # re-render, same unit
{{ read_celsius  :: convert_C_F :: write_1dp }}       # unit change + render
```

**`write_*` normalizes first, then renders** (per the datagoodr note): internally
`write_X(v) = render_X(canonicalize(v))`, where `canonicalize` is the `read_*`/
`as_*` recast. So `write_*` is safe to call on already-stable *or* raw-ish input
— it idempotently re-reads before writing. That keeps `read_* :: write_*` robust
even when the caller hands it a half-cleaned value.

**Mapping to the current code.** `read_*` aliases the existing verb table in
`R/20-fx-stabilize.R` (`as_mmddyyyy`, `as_email`, `as_ein`, …); datagoodr already
renamed its ingest verbs `as_* → read_*`, so the vocabularies line up. `write_*`
is net-new: a small renderer per `format_style` (below). `convert_*` is a third,
smaller registry keyed on `(from_unit, to_unit)` — most units have no converter
and that is fine (the pair is simply unavailable).

## 2. The leaf is two axes: `format_style` and `unit_type`

`format_label` today is mostly a copy of `semantic_type` (`calendar/calendar`,
`usd/usd`, `email/email`) and only occasionally does real work
(`range/{comma_pair,to_range}`, `coordinate/{dms,iso6709}`). The proposal — a
good one — is to replace it with two orthogonal sub-axes so a variant is a
*combination* rather than an enumerated leaf:

- **`format_style`** — the *written rendering* that determines parse and render
  but not meaning: date field-order **and** separators (the mask together),
  currency suffix-scaling (`$12b`), abbreviated-vs-full (`CA` vs `California`),
  comma-pair vs `lo to hi`. This is what `read_*`/`write_*` key on. Usually
  value-detectable.
- **`unit_type`** — the *dimensional or categorical unit* that carries meaning
  and may need a `convert_*` or is metadata-gated: `USD`/`EUR`, `C`/`F`,
  fiscal-vs-calendar year, measurement unit (`kg`/`m`), geographic level
  (`state`/`county`/`country`). Often **not** value-detectable, so frequently
  `NA`.

A variant = `(semantic_type, format_style?, unit_type?)`, either sub-axis
optional. **Define a variant only as far as it affects parsing** — if a type has
one style and no meaningful unit, both are `NA` and the leaf is the
`semantic_type`. Depth 4 is reached when **either** sub-axis resolves; resolving
`format_style` alone is still depth 4 even if `unit_type` stays `NA` (datagoodr
renders that as an empty unit facet).

### Settled: order lives in `format_style`

Date field-order (`mmddyyyy` vs `ddmmyyyy` vs `yyyymmdd`) and separators both
live in `format_style` — together they are the mask the parser needs, and order
is a parse parameter, not a unit of measure (the unit of a calendar date is
always day-of-month-of-year). `unit_type` is reserved for a genuine
dimensional/categorical unit where a `convert_*` or a metadata gate is
meaningful. This keeps "resolve the unit" meaning one coherent thing in every
family, and it is the axis datagoodr asked to surface resolved on `$route`
(their ask 3), so the two converge on the same field.

### Worked mapping

| path | today `format_label` | → `format_style` | `unit_type` |
|---|---|---|---|
| temporal/date/calendar | `calendar` | `mdy_slash` · `ymd_dash` · `mdy_smash` | — |
| temporal/period/year | `year` | `bare` · `FYyyyy` | `calendar` · `fiscal` |
| number/currency | `usd` / `euro` / `balance` | `plain` · `grouped` · `suffix_scaled` · `accounting` | `USD` · `EUR` |
| number/quantity/measurement | `measurement` | `plain` | `kg` · `m` · `C` · `F` … (metadata) |
| text/name/place | `place` | `abbreviated` · `full` | `state` · `county` · `country` |
| number/range/min_max | `comma_pair` / `to_range` | `comma_pair` · `to_range` · `bracketed` | — |

This collapses the `usd`/`euro`/`balance` and `comma_pair`/`to_range` enumerations
into one `semantic_type` row crossed with the two small, controlled vocabularies,
and kills the `format_label == semantic_type` redundancy across most of the 96
rows. The detector's job becomes: match the `semantic_type`, then resolve any
`format_style` (and `unit_type` where values permit) — any combination.

## 3. `dd_data_unit` → `unit_type`

Rename `dd_data_unit` to **`unit_type`** and move it to sit **after**
`format_label`/`format_style` in the column order. Today it holds a *menu* of
possible units (`measurement → unit-specific (kg;;m;;C;;L)`); under the new model
it becomes the resolved (or candidate) value of the unit axis. This is one
concept, not two — the rename and the `format_label` split land together, or we
end up with two "unit" fields. The temperature case is the payoff: `unit_type` of
`C` with a defined `convert_C_F` and a `desired_default_format`/target unit of `F`
gives a real, declarable unit transform.

## 4. New ontology columns (datagoodr asks 3 & 4)

- replace `format_label` with `format_style` + `unit_type` (unit_type from the
  renamed `dd_data_unit`).
- `stable_format` → **examples only**; move any verb token out of it.
- add **`desired_default_format`** — the `write_*` target to pre-fill when the
  human expresses no preference (`yyyymmdd` for calendar, `numeric` for a USD
  amount). For units, the default target unit lives here too (e.g. keep `C`, or
  a project default of `F`).
- carry `read_*`/`write_*` tokens in a format DSL with prefix discipline
  (`fx:` token · `strp:` R format · `re:` regex) and `::` reserved for compose
  (datagoodr ask 6).

## 5. Migration surface (why this is v7, not an edit)

Touches: the 96 ontology rows + `variant_id` scheme; `R/14-fx-ontology.R`
(`fx_validate_ontology` axis checks); the router (`format_label` is a training
label/feature); the verifier and `$route` builder (`R/02-01-guess-data-type.R`);
`fx_stabilize()`'s lookup key (currently `semantic_type` + `format_label`); the
Sherlock/GitTables crosswalk; and datagoodr's governance mapping. Sequence:

1. **v7 schema** — add `format_style` + `unit_type` (+ `desired_default_format`),
   backfill from today's `format_label`/`dd_data_unit`, keep `format_label` as a
   derived convenience for one release.
2. **`write_*` renderers** for the high-frequency styles, then compose
   `read_* :: write_*` behind `fx_stabilize(..., target_format=)`.
3. **`convert_*`** registry, starting with temperature and fiscal/calendar year.
4. **detector** resolves `format_style` (and `unit_type` where value-detectable)
   as the depth-4 step; router/verifier retrained on the new label axis.

## 5a. Transformability as a path search (prototyped)

With input and output both expressed as a format `(semantic_type, unit_type,
format_style)`, stabilizing a column is a **graph search**: is there a path from
the input format to the desired one through the registry of
`read_`/`write_`/`convert_` edges? A path exists only "if you can get there from
here" — a unit change needs a registered `convert_*`, so the search *answers* the
transformability question instead of assuming it.

Nodes are value states; edges are the three operations:

```
written(style_a) --read_a-->  canonical(unit_a) --convert_a_b--> canonical(unit_b) --write_b--> written(style_b)
```

`R/22-fx-transform-path.R` implements this as a first, additive increment (not
yet wired into `guess_data_type()`/`fx_stabilize()`):

- `fx_format(semantic_type, format_style, unit_type)` — a format descriptor.
- `fx_plan_transform(from, to)` — breadth-first search of `fx_transforms()` for
  the shortest `read :: [convert] :: write` composition; returns an `fx_plan`
  marked transformable with the path, or not-transformable with a reason.
- `fx_transformable(from, to)` / `fx_apply_plan(x, plan)`.

The seeded registry demonstrates the three cases: temperature `celsius → C →
(convert_C_F) → F → fahrenheit` **resolves**; a calendar reformat with no unit
change resolves; and fiscal-year → calendar-year is reported **unreachable**
because `convert_fiscal_calendar` (which needs the fiscal-year-end convention) is
deliberately not registered. v7 grows this registry by generating `read_`/
`write_` edges from each ontology row's `format_style` and registering
`convert_` edges per `unit_type` pair as they are defined.

## Status (2026-10-26)

Done and shipped on `main`:

- **Schema** — `format_style`, `unit_type` (renamed from `dd_data_unit`),
  `desired_default_format` added; `format_label` kept derived. Validation clean.
- **Planner** — `fx_format` / `fx_plan_transform` / `fx_transformable` /
  `fx_apply_plan`, with canonical endpoints.
- **Registry** — generated from the ontology (a `read_<style>` edge per row) and
  merged with the hand-authored `write_`/`convert_` seed.
- **Stabilizer** — `fx_stabilize(..., target_format=)` renders via the planner;
  `$route` carries `format_style`.
- **Detectors** — `day_of_week` / `month_of_year` wired with selective `as_dow` /
  `as_moy`; `first_name` / `quarter` / `domain` reconciled. 41/96 implemented.

Since shipped: the **disambiguator** (a `disambiguator` / `collision_group`
column + a cardinality tie-break in the verifier, resolving the `geographic` and
place↔geographic collisions, guarded by `fx_validate_ontology()`); a
**`conversion_log`** + warning on `fx_stabilize()` for dropped values; a
**named-color leaf** (`text/color/color_name` + `is_color_name()`); and a
**`write_numeric`** edge so plain numbers stabilize to numeric. Coverage 47/97.

The migration and the new API surface are complete. Deferred (next release, each
its own effort):

- **Router retrain** — not needed now (the router trains on `format_label`, which
  is retained); required only when `format_label` is finally removed.
- **Broad `write_` renderers** — the registry's write side is still mostly a
  seed (`write_numeric` and the calendar/temperature styles exist); grow it so
  `target_format` works for more styles.
- **True multi-style detection** — `$route` carries the resolved variant's
  `format_style`; sniffing a column to choose among several styles within one
  semantic_type (mdy vs dmy vs ymd) is a detector enhancement.
- **`convert_` edges per unit pair** — temperature done; fiscal/calendar year
  needs the fiscal-year-end convention from datagoodr. (The currency-amount
  detector is done — `usd` / `is_currency_amount`.)
- **A `tags` detector** — a flat delimited set (`a|b|c`) is
  `categorical/multiselect/tags`, recognizable by a consistent delimiter that
  splits into repeated members; not built (datagoodr starwars report).

## 6. Does separating add clarity? — verdict

Yes. It removes a redundancy that affects most of the ontology, turns an
enumerated leaf set into a compositional space the detector can resolve one axis
at a time, and — most importantly — separates the three operations (detect /
render / convert) so that user-controllable output and genuine unit conversions
(temperature, currency) each have a home. The cost is a real v7 migration, and
the one caveat is to keep `unit_type` for true units (not date field-order) so
"resolve the unit" means the same thing in every family.
