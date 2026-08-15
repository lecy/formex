# Ontology Design Principles

## What this ontology is for

It is a taxonomy for **inference**, not for meaning. Every structural decision
answers one question: *does this distinction help a machine guess correctly
from the data alone?* A distinction that is important to a domain expert but
invisible in the values does not earn a row.

This is the inverted priority from most ontologies, and it is the reason this
one cannot be crosswalked 1:1 to a meaning-based ontology like DBpedia. The two
partition the same space along different axes.

Second purpose, equally binding: each row must specify how a raw manifestation
becomes a **stable representation without information loss**, and how that
stable representation must be ingested so it survives a CSV round-trip in the
absence of a schema. A row that classifies but cannot round-trip is incomplete.

---

## The seed

Start from the smallest defensible set. The original four map to R's storage
modes:

```
numeric    character    factor    logical
```

Everything in the current ontology is a descendant of those four. `identifier`,
`temporal`, and `structured` were promoted to top-level types not because they
are conceptually grand but because they behave differently enough at detection
time to justify separate treatment — identifiers are numeric-looking but never
arithmetic, temporals have their own format grammar, structured values are
compound.

**The burden of proof is on expansion.** A compact ontology that classifies
well beats an exhaustive one that classifies poorly, because every additional
node adds a discrimination problem and needs its own banked examples.

---

## Vocabulary

| Column | What it names |
|---|---|
| `data_type` | The **modality** — which operations are meaningful on this data |
| `semantic_family` | The broad kind of thing |
| `semantic_type` | **The unit of analysis.** The thing a detector predicts and is scored on |
| `format variant` | One way of writing a semantic type down |

`semantic_type` is deliberately the term used across the column-type-annotation
literature, so the work is legible without translation.

`data_type` is **not** storage type. Storage modes do not carve the space
usefully: categorical variables, identifiers, and serialized structures have no
distinct storage mode of their own — they are all strings. What separates them
is what you are permitted to *do* with them.

---

## The split ladder

Four levels, each with its own admission test:

| Level | Question | Admit a new node when |
|---|---|---|
| **data_type** | What operations are admissible? | The candidate supports a distinct operation set |
| **semantic_family** | What broad kind of thing is it? | It inherits the type's operations and adds shared parsing or validation |
| **semantic_type** | What is it, specifically? | Meaning differs **and** the difference is detectable from data |
| **format variant** | How is it written? | It needs a different transform expression |

### data_type is defined by admissible operations

You cannot difference a string. You can difference a date or a dollar amount,
so conceptually those are numbers — but differencing two dates yields a
*duration*, not a date, which is why temporal is its own modality rather than a
family under number. Identifiers look numeric and are never arithmetic: the
only admissible operations are equality and joins.

| data_type | Admissible operations | Why not a neighbour |
|---|---|---|
| `number` | arithmetic, differencing, aggregation, ordering | — |
| `temporal` | ordering, differencing (→ duration), binning | differencing is not closed; summation is meaningless |
| `identifier` | equality, joins, counting distinct | digits, but arithmetic is never valid |
| `categorical` | equality, grouping, counting; ordering only if ordered | closed vocabulary, no arithmetic |
| `boolean` | logical algebra, counting, rate calculation | two-valued, special-cased everywhere |
| `text` | matching, tokenizing, lexical ordering | no closed vocabulary asserted |
| `structured` | must be decomposed before any operation | compound; operations belong to the parts |
| `unknown` | none asserted | the honest default |

This is why the top level is nearly closed. New operation sets are rare, and
adding one is a much larger claim than adding a family or a type.

---

## Inheritance: what makes the levels cohere

The tree is an inheritance chain in the object-oriented sense, and that is not
decoration — it is the rule that determines whether a proposed node belongs
where you want to put it, and the thing that makes extension a decision
procedure rather than a matter of taste.

> **Every child satisfies every constraint of its parent, and adds at least
> one of its own.**

Two tests, both of which a candidate must pass:

- **Inheritance test.** Anything true of the parent must be true of the child.
  If a candidate violates a property of the family it is being filed under,
  either the family is wrong or the candidate belongs somewhere else. A
  `semantic_type` under `number` that cannot be summed or differenced is not a
  number; it is an identifier that happens to be written in digits.
- **Extension test.** The child must add at least one property the parent does
  not have. A child that adds nothing is a synonym of its parent, not a
  specialization, and it should not get a row.

### The three questions when adding a new node

1. **Is this a new instance of a `semantic_family` that already exists?**
   Most additions are. File it and stop.
2. **Is it the first case of a new family?** Only if it shares a `data_type`
   with existing families but satisfies none of their constraints. Species
   names would suggest a `taxonomy` family — genus, phylum, kingdom, and family
   names all share Latinate morphology, title case, a near-closed controlled
   vocabulary, and single-or-binomial token structure. That is a family, and it
   is a different one from `name` or `label`.
3. **Does it fit under any existing `data_type` at all?** If the operations it
   admits are genuinely new, it needs a new modality — a much larger claim, and
   rare.

### A family with one member

Not wrong, but it is a bet that more members are coming. Track it: if a family
is still a singleton two ontology versions later, the bet lost. Collapse it
into its parent rather than keeping a level that never branched.

---

## Formats do not inherit

The fourth level is a different relation from the first three, and conflating
them causes real confusion.

Levels 1–3 are **specialization**: each child *is a kind of* its parent, and
inherits its properties. Level 4 is **re-expression**: `2024-03-15` and
`03/15/2024` are not two kinds of calendar date. They are the same date written
twice.

Format differences are usually arbitrary. They carry no meaning of their own
and are worth an ontology row for exactly one reason: **they pose distinct data
processing challenges.** A row exists so a governance rule can attach to it.

This is also why format is not a level in `path_distance`, and why the scoring
unit is the `semantic_type`. Confusing two formats of one type is a non-error;
confusing two types is an error. The distance metric has to reflect that.

---

## The three format columns are a refinement roadmap

Each format row carries three rules, and they point at three different
destinations. Read together they are a rule-based data refinement pipeline:

| Column | Question it answers | Destination |
|---|---|---|
| `data_format` | How do I recognize this, and how do I read it in **without corrupting it**? | the parser |
| `raw_to_stable_transform` | How do I re-express it in a **canonical, corruption-resistant** form? | the archive |
| `stable_import_rule` | How should the stable form be **ingested so it lands ready for analysis**? | the analyst |

```
raw  --[data_format]-->  read safely
     --[raw_to_stable_transform]-->  store safely
     --[stable_import_rule]-->  load usefully
```

The middle step is the one that serves sharing, provenance, and preservation.
It exists so that a file leaving your hands does not degrade in someone else's
— the stable form is chosen to survive readers you do not control, which is
what the round-trip stress test measures.

The third step exists because surviving a reader is not the same as arriving in
a useful shape. A factor stored as text survives perfectly and still imports as
a character vector; the import rule is what promotes it. **Safe and useful are
different targets, and they need different rules.**

---

## The three-way test for any new distinction

When two manifestations differ, ask in this order:

### 1. Does the difference change what the value *means*?
→ **New semantic_type**, but only if it passes the guessability test below.

`identifier/id/geographic` (FIPS) and `categorical/mutually_exclusive/classification_code`
(NAICS) mean different things.

### 2. Does the difference change how the value is *written*?
→ **New variant** (a new row under the same semantic_type), if and only if it
requires a different transform expression. See the variant rule below.

`2024-03-15` and `03/15/2024` mean the same thing and differ only in surface.

### 3. Does the difference change only the *unit*?
→ **Neither.** Units are dictionary metadata, not ontology structure.

`100 lbs` and `100 kg` are the same semantic_type, same variant. The unit lives in
`dd_data_unit`, because it affects interpretation but not parsing or
representation.

**Units are not formats.** This is the rule most likely to be violated by
accident, because a unit suffix looks like a format difference. It isn't: the
parse is identical, the stable representation is identical, and only the
dictionary entry changes.

---

## The variant rule

> **One row per transform expression, not per surface appearance.**

If two manifestations are reachable by the same formex expression, they are the
same variant. The row defines a *rule*, not an *appearance*.

Worked example, USD currency:

| Raw | Expression | Same row? |
|---|---|---|
| `$87,000` | `{{ [strip:$,][range:-Inf,Inf][dec:.2] }}` | yes |
| `13.76$` | same | yes |
| `13.76 USD` | needs a token-aware strip | **no — new variant** |

The first two share a transform; the third does not, because stripping `$` and
`,` leaves `USD` behind.

### A row may need more than one detector

`$87,000` and `87000` could share a transform, but their signatures are
nothing alike — one is punctuation-heavy, the other is bare digits. That is
fine. The row is the transform equivalence class; detection within a row is
one-to-many, and the OR-wrapper already accommodates it: a semantic_type fires if
**any** of its registered detectors matches.

Keeping rows at the transform level is what keeps the ontology compact. Pushing
detection complexity into the detector layer is what keeps it honest.

### Warning: the `examples` column is currently doing two jobs

Some entries are *recognizable manifestations* — things a detector should
identify as this type from the values alone. Others are *acceptable parser
inputs* — things the transform must handle once the type is already known.

Bare `87000` is the second kind. Nothing in those digits says "currency"; that
comes from the header or the dictionary. Under a guessability-based ontology,
only recognizable manifestations belong in the detection example set. Consider
splitting the column, or tagging each example as `detect` vs `parse`.

---

## The guessability test (and the collapse rule)

A semantic_type split is only valid if the semantic_typees are **separable from the data
alone**. This is testable, not a judgment call:

> Bank examples of both. Compute `signature_distance`. If no detector can
> separate them above chance, the split is not supported and the semantic_typees
> **collapse back into one**.

This runs in both directions. It prevents the ontology from growing
distinctions the data cannot support, and it flags existing ones that should be merged. It also gives ontology maintenance an objective stopping rule rather
than relying on the maintainer's patience.

A meaning-based distinction that fails this test does not disappear from the
world — it just isn't ontology structure. It becomes a dictionary attribute,
which is where FIPS-vs-NAICS-style distinctions ultimately have to live anyway.

---

## Homogeneous vs heterogeneous unit columns

The unit rule above assumes the unit is **constant down the column**. When it
varies, stripping becomes lossy and the row structure changes:

| Column | Situation | Handling |
|---|---|---|
| `100 lbs`, `200 lbs` | unit constant | strip to number, unit → dictionary. Lossless. |
| `100 lbs`, `60 kg` | unit varies, one dimension | convert to canonical unit **or** split into value + unit columns |
| `100 F`, `30 miles` | unit varies across dimensions | not one variable. Flag as a data quality failure. |

This is decidable from the data rather than by inspection: `last_tok_top_share`
from the token feature block, combined with a hit against the unit lexicon.
Near 1.0 means a constant unit and a safe strip. Below that means the column
carries information in its unit tokens that stripping would destroy.

---

## What never gets a row

- A distinction visible only in the column header
- A distinction visible only in domain context
- A unit
- A validation rule (that is a column, not a node)
- A storage preference (also a column)
- A surface form reachable by an existing transform expression

---

## Identity

- `semantic_type_id` (`n0042`) is immutable and opaque. **Cases reference this
  and nothing else.** It survives renames, moves, and reparenting.
- `variant_id` (`n0042-f01`) is immutable. **Detectors, transforms, and import
  rules reference this.** `f` for format expression — deliberately not `v`,
  which reads as semantic versioning.
- `node_label` (`NUM-QUA-n0042-f01`) is **derived and regenerated**. It is for
  human eyes only and is never stored as a foreign key or diffed for identity.
- Counters are **allocated, never counted**. A deprecated `n0042` leaves a
  permanent hole. Renumbering densely would silently repoint every case that
  referenced the old node.

Lifecycle — versioning, deprecation, and retirement — is covered under
Extensibility at the end of this document, since those columns exist to serve
change rather than to describe the current state.

---

## Why the ontology is nested

The hierarchy is not organizational tidiness. It is the mechanism that makes a
**partial answer** possible, and partial answers are the normal case.

We know it is a fruit. We are not sure it is a Granny Smith. So we label it
`fruit` and stop. That is not a wrong answer — it is a true answer given at the
depth the evidence supports.

> **Graceful failure is omission of granularity, not misclassification.**

A flat list of 85 semantic types would force every detector into a binary:
commit to a leaf, or abstain entirely. Both are bad. Committing manufactures
false precision; abstaining throws away the substantial information that a
column is numeric, or temporal, or an identifier. A nested ontology lets the
system return exactly what it knows.

### A prediction is a path prefix, not a leaf

```
number                          confident
number/currency                 confident
number/currency/usd             not supported by the data -- stop here
```

Every prefix of a valid path is itself a valid prediction. Confidence declines
monotonically with depth, and the system descends only while the evidence
holds. This is what the cascade is actually doing: each stage decides whether
to go one level deeper, not which of 85 leaves to pick.

### This is why per-row accuracy is the wrong metric

Predicting `number` when the truth is `number/currency/usd` is a **truncation**,
not an error. Scoring it as a miss punishes the system for being honest, and
optimizing that metric would push it toward confident wrong leaves.

Two numbers describe performance properly:

- **depth achieved** — mean depth of the predictions
- **depth accuracy** — share of predictions correct *at the depth claimed*

A system that always stops at depth 1 has perfect accuracy and no utility. One
that always predicts leaves has maximum depth and poor accuracy. The frontier
between them is the thing to optimize, and it is a property of the whole
cascade rather than of any component — which is what "model fit is by class,
not by row" means operationally.

### It also bounds how deep the ontology should be

Depth is only worth adding while the levels are separably detectable. A
six-level tree whose bottom three levels are never distinguishable is three
levels of theatre: it inflates apparent granularity while every prediction
truncates at level three anyway. The collapse rule applies to depth as well as
to siblings.

---

## The default class as a safety net


A detector failure is not one thing. Two outcomes must be distinguished:

- **Failure of precision** — `87000` fails the USD detector, fails the currency
  detector, and lands in `number`. The type is right; only the granularity is
  lost. This is an acceptable outcome and requires no correction.
- **Failure of type** — `87000` routes to `text` or `categorical`. This is a
  real failure, because downstream handling is now wrong.

`data_format_default_type` and `data_format_default_class` exist to make the
first outcome deterministic rather than incidental. When a value is
**underspecified** — when the data itself carries no signal that could route it
to the granular node — the fallback columns say where it lands.

This has a direct consequence for what does and does not get a row:

> **A manifestation only earns a row if the data alone can route it there.**

There is no `number/currency/usd` row for bare `87000`, because nothing in
those digits says currency. Currency-ness arrives from the header, the
dictionary, or the human reviewer. Listing it as a row would train a detector
to claim territory it cannot defend, and the misfire would be invisible because
the label would look correct.

This supersedes the "one row, many detectors" idea. A row's detectors and its
transform cover the same set of manifestations; anything the transform accepts
but no detector can recognize is handled by the fallback, not by a second
detector. The narrow exception is genuine mask variation within one transform
(`13.76 USD` and `USD 13.76`), which is one row with two patterns.

**The first guess is meant to be rough.** Output feeds a data governance file
that a human reviews and overrides — a reviewer who knows the file is all
financials will promote `number` to `number/currency/usd` themselves, which
unlocks the class-based functionality. That changes the cost function: the cost
of a wrong guess is reviewer attention, not silent corruption. Precision
gating should therefore be tuned to minimize review burden and to keep failures
legible and ranked, not to approach precision 1.0 as an autonomous system would.

### Two failures that look identical

The fallback fires in two very different situations, and the output is the same
either way:

| | Cause | Is the fallback correct? |
|---|---|---|
| **Underspecification** | The data carries no signal that could route it deeper. `87000` is not recognizably currency. | **Yes.** No detector could have done better. |
| **Detector inadequacy** | The signal was present; the detector missed it. | **No.** The fallback is masking a real bug. |

Because the output is identical, production data alone cannot tell them apart —
which is a strong argument for the test bank. Compare the **production fallback
rate** for a type against its **banked fallback rate** on cases known to be
recognizable. Agreement means underspecification. Divergence means the detector
is weaker in the wild than on the bench, and points at exactly which type to
work on next.

### The fallback must be a proper ancestor

A hard rule, and one that is mechanically checkable:

> A fallback may only move **up** the path. Never sideways.

Falling from `usd` to `eur` is misclassification. Falling from `usd` to
`currency`, or to `number`, is truncation. Any fallback target that is not a
prefix of the attempted path is a bug in the ontology, not a graceful failure.


---

## Stable representation

A **stable data type** is one that any generic CSV reader will ingest into an
in-memory representation preserving the integrity and the meaning of the
variable.

> A variable can be stabilized only if the transformation causes **no loss of
> information** while **improving representation**. Both halves are required.

### Three corruption mechanisms, three different tests

| Mechanism | Example | Test |
|---|---|---|
| **Value destroyed** | FIPS `06037` read as integer → `6037` | Compare characters after round-trip |
| **Meaning misread** | `MAR1` gene symbol → 1-Mar; `ACGT` → date | Screen against known reader triggers |
| **Grammar ambiguous** | `03-04-2024` — dd-mm and mm-dd share a mask | Do two readers or two locales disagree? |

Only the third is fixed by choosing a canonical format (`yyyy-mm-dd`). The
first is fixed by forcing a storage type. The second cannot be fixed by the
data at all and needs an import rule.

### Every strip needs a receipt

The losslessness half of the rule reduces to one testable condition:

> Anything removed by a transform must be either **provably redundant across
> the column** (constant, therefore recoverable) or **recorded elsewhere**
> (dictionary, unit field, metadata column).

`[strip:$,]` is legal because the comma is redundant and the currency is
recorded in the dictionary. Stripping `lbs` is legal when the unit is constant
and captured in `dd_data_unit`; it is **illegal** when the unit varies down the
column, because nothing recovers it. This is the same rule that governs units,
stated generally.

Two mechanical properties every transform should satisfy:

- **Idempotent** — `stable(stable(x)) == stable(x)`
- **Row-independent** — the transform of a value never depends on its position

---

## When a stable import rule is necessary

> **Heuristic:** once transformed into its most stable version, will stats
> programs or Excel guess the correct data type? If yes, no rule. If no, a rule.

This is testable rather than a judgment call. `roundtrip_check.R` implements
it: write the stable values to CSV, read them back with default reader
settings, and compare against `default_storage`. Four triggers, any of which
requires a rule:

```
VALUE_CHANGED               characters did not survive the round-trip
TYPE_WRONG                  inferred class differs from default_storage
READER_DISAGREE             two readers infer different classes
NOT_INFERABLE_FROM_VALUES   factor, ordered, date -- never inferable, always a rule
EXCEL_HAZARD                matches a known Excel corruption trigger
```

Run across the current ontology, **26 of 87 rows (30%) require an import
rule.** The breakdown: 19 TYPE_WRONG, 7 EXCEL_HAZARD, 5 NOT_INFERABLE, 2
VALUE_CHANGED. Concrete cases include `identifier/id/geographic` (FIPS `06037`
read back as integer `6037` — both value-destroyed and type-wrong),
`categorical/mutually_exclusive/geographic` (a factor, never inferable from
values), and `temporal/date/calendar` (Excel date coercion).

The remaining 70% need no rule, which is the useful result: the stable format
alone carries them, and `stable_import_rule` can be left empty rather than
populated defensively.

### One caveat on "stable"

Stability is reader-relative. `yyyy-mm-dd` is unambiguous to R and pandas, but
Excel will still convert it to a date serial and may re-render it in locale
format on save. So the stable format and the import rule are a **pair**, not
alternatives — the format removes ambiguity, the rule pins the interpretation
for readers that guess anyway.

---

## Completing the round trip: invertibility

The stress test above asks whether the stable form survives a reader. The other
half of the round trip asks whether the **raw form can be recovered from the
stable form**.

> A transform is sound if `T⁻¹(T(raw))` recovers the raw **information**, or if
> the difference is confined to a **declared, bounded** loss.

### Information invertibility vs presentation invertibility

These are different requirements and only one of them is mandatory.

- **Information invertibility (required).** Everything that distinguishes one
  value from another must be recoverable. `$87,000 → 87000` is sound because
  the currency lives in the dictionary and the thousands separator is
  redundant. `06037 → 6037` is unsound because the leading zero distinguishes
  a FIPS code from an integer and nothing else records it.
- **Presentation invertibility (optional).** Recovering the exact original
  rendering — `$87,000` rather than `87000.00` — requires knowing a display
  convention. That is presentation metadata, not data. It belongs in the
  governance file for formatting output, and its absence never compromises
  data integrity.

Confusing the two leads to over-conservative transforms that refuse to strip
anything.

### The three allowable losses

1. **Redundant formatting recorded elsewhere** — currency symbols, thousands
   separators, unit tokens when the unit is column-constant and captured in
   `dd_data_unit`.
2. **Declared precision reduction** — deliberate, with a stated bound.
3. **Canonical reordering** — `03-04-2024 → 2024-03-04` discards nothing; it
   only removes ambiguity.

Not allowable: leading zeros, unit tokens that vary down the column, case in
case-sensitive identifiers, whitespace that is significant.

### Worked example: coordinates

Projection and notation changes are genuinely bidirectional — the coordinate
does not move, only its expression.

```
raw       40°44'55" N
stable    40.7486111111        (full double precision)
recovered 40 44 55 N           exact
```

Rounding is where the declared loss appears:

```
stable    40.7486   (4 dp)  -> recovered  40 44 54.96 N   error 0.04" ~ 1.2 m
stable    40.74861  (5 dp)  -> recovered  40 44 54.9996 N error 0.0004" ~ 1 cm
```

| Decimal places | Ground resolution at the equator |
|---|---|
| 3 | 111 m |
| 4 | 11.1 m |
| 5 | 1.11 m |
| 6 | 0.11 m |
| 7 | 0.01 m |

Truncating to four decimal places is a legitimate stabilization **only if the
row declares it** — a choice to accept ~11 m resolution, not an accident. That
is the distinction the ontology has to record.

### Suggested columns

```
stable_to_raw_transform   the inverse expression, where one exists
lossy_by_design           what is deliberately discarded, and why
precision_bound           the magnitude of the accepted loss, in real units
```

A row where the transform is not invertible and `lossy_by_design` is empty is
an unaudited transform, and should fail validation.

---

## Annotated Excel import pathologies

Excel is the most common downstream consumer of research CSVs and the most
aggressive at reinterpreting them. Grouped by mechanism, because the remedy
differs by group.

### A. Type coercion on read

| # | Pathology | Trigger | Damage | Remedy |
|---|---|---|---|---|
| A1 | Leading zeros stripped | `^0\\d+` | `06037 → 6037`. Hits FIPS, ZIP, EIN, SSN, phone, account and routing numbers, any zero-padded code | Force text; import rule required |
| A2 | Identifier read as date | `d-d`, `d/d`, `d.d` patterns | `1-2 → 2-Jan`. Hits version strings, ratios, ranges, dotted codes | Force text; avoid hyphen/slash in stable form |
| A3 | Gene and product symbols read as dates | `MAR1`, `SEPT2`, `DEC1`, `OCT4` | Silent conversion to a date serial. Widespread enough in genomics that HGNC renamed affected gene symbols | Force text |
| A4 | Nucleotide strings read as dates | short `[ACGT]` runs and similar | `DEC` and month-like fragments convert | Force text |
| A5 | Fractions read as dates | `1/2`, `3/4` | `3/4 → 4-Mar` | Force text |
| A6 | Scientific-notation strings evaluated | `1E5`, `2E3` | `1E5 → 100000`. Hits alphanumeric product and gene codes | Force text |
| A7 | Boolean words coerced | `TRUE`, `FALSE` | Become logical; string case is lost on re-export | Force text if the literal matters |
| A8 | Missing-value tokens become error cells | `#N/A`, `#NULL!` | Become native error types, no longer readable as strings | Use empty or a non-`#` sentinel |

### B. Precision loss

| # | Pathology | Trigger | Damage | Remedy |
|---|---|---|---|---|
| B1 | 15-significant-digit ceiling | numeric strings ≥ 16 digits | Digits beyond the 15th become zeros. Hits credit cards, IMEI, long barcodes, large surrogate keys | Force text |
| B2 | Scientific notation display | large or small magnitudes | Value is intact in memory but the **displayed and re-exported** form is `1.23E+15` | Force text, or fix column format |
| B3 | Floating-point display rounding | many decimal places | Re-export writes the rounded display value | Declare `precision_bound` |
| B4 | Time as fraction of a day | `hh:mm:ss` | Durations over 24 h wrap; `25:30` becomes next-day | Store as numeric minutes or ISO 8601 duration |
| B5 | 1900 leap-year bug | dates before 1 Mar 1900 | Excel treats 29 Feb 1900 as real, so serials are off by one | Avoid serials; store ISO strings as text |

### C. Locale dependence — the same file, different results on different machines

| # | Pathology | Trigger | Damage | Remedy |
|---|---|---|---|---|
| C1 | Ambiguous date order | `03/04/2024` | US reads Mar 4, most of Europe reads 3 Apr. Silent, and it differs by machine | ISO `yyyy-mm-dd`, plus an import rule |
| C2 | Decimal separator inversion | `1,234` | Comma is a thousands separator in some locales and a decimal point in others | Strip separators at stabilization; declare in the transform |
| C3 | List separator | `;` vs `,` as the CSV delimiter | Files split into the wrong columns entirely | Declare the delimiter; prefer quoted output |
| C4 | Currency symbol parsing | `€1.234,56` | Symbol and separator conventions vary together | Strip to bare number; unit in the dictionary |

### D. Parsing and security

| # | Pathology | Trigger | Damage | Remedy |
|---|---|---|---|---|
| D1 | Formula injection | leading `=`, `+`, `@`, or `-` before a non-digit | Cell is evaluated as a formula. Also a genuine security issue for exported CSVs | Prefix a text qualifier on export; flag on import |
| D2 | Autocorrect on edit | manual entry or autofill | Values silently altered during human editing | Out of scope for import, but worth flagging in the governance file |
| D3 | Whitespace invisibility | leading, trailing, or non-breaking spaces | Comparisons and joins fail with no visible cause. Non-breaking spaces arrive via web paste | Trim at stabilization; treat `U+00A0` explicitly |
| D4 | Quoting inconsistency | embedded delimiters, unescaped quotes | Row alignment breaks mid-file | Validate field counts on read |

### E. Capacity and encoding

| # | Pathology | Trigger | Damage | Remedy |
|---|---|---|---|---|
| E1 | Row ceiling | > 1,048,576 rows | Silent truncation on open | Never route large files through Excel |
| E2 | Cell character ceiling | > 32,767 characters | Long text truncated | Flag long-text columns |
| E3 | UTF-8 without BOM | non-ASCII characters | Mojibake in names, addresses, place names | Write UTF-8 with BOM when Excel is a target consumer |

### Which of these the stress test can detect

`excel_hazards()` screens for A1, A2, A3, A4, A6, B1, B2 and D1 — the ones with
a reliable textual signature. The locale group (C) cannot be detected from
values on one machine, because the corruption is a property of the reader
environment rather than of the data; those rows need an import rule on
principle. The capacity group (E) is a file property, not a column property.

**Treat the screen as a flag for inspection, not a verdict.** It is a list of
known triggers, not a simulation of Excel. It has already produced one false
positive in development — negative numbers matching the formula-injection
pattern — which is a fair warning about the rest.

---

# Extensibility

## The core is deliberately incomplete

**This ontology is not exhaustive and is not trying to be.** It captures the
generic data constructs that most users encounter — the ones that cause
disproportionate pain to anyone who has cleaned a dataset or tried to
standardize fields so that sources can be combined. Leading zeros on codes.
Dates that mean different things on different machines. Currency written six
ways. Identifiers that look like numbers.

Those problems are universal, and a compact core that handles them well is more
useful than a sprawling one that handles everything badly. Every node added to
the core is a node every user carries, every detector must discriminate
against, and every scoring run must cover.

Domain specificity is added by **extension**, not by growing the core.

A researcher working with clinical data needs ICD-10 codes, NPI numbers, and
LOINC identifiers. One working with nonprofit filings needs EINs, NTEE codes,
and FIPS. One working with genomics needs accession numbers and gene symbols.
None of those belong in a core that all three share — but all three should be
able to declare them without forking anything.

### The core-membership test

> A node belongs in the core if it is encountered across **unrelated domains**.
> Otherwise it belongs in an extension.

Dates, currency, postal codes, and email addresses pass. NTEE codes do not —
they matter enormously in one domain and are invisible everywhere else. This is
a test about breadth of encounter, not about importance.

The test runs in both directions. An extension node that turns up
independently in three unrelated extensions has demonstrated it is generic, and
is a candidate for promotion into the core.

## How an extension attaches

An extension is a set of additional rows obeying the same schema and the same
admission tests. Three rules keep extensions from colliding with the core or
with each other:

1. **Extensions attach under an existing `data_type`.** If a candidate needs a
   genuinely new modality — a new set of admissible operations — that is a core
   change, not an extension, and it should be argued as such.
2. **Extensions mint IDs in their own namespace.** Core uses `n0042`;
   an extension uses a prefixed range (`nccs-0007`, `icd-0031`). Core and
   extension IDs then never collide, and a case file's label immediately
   discloses which vocabulary it was drawn from.
3. **Extensions inherit, they do not override.** An extension node must satisfy
   every constraint of the core parent it attaches to. An extension that needs
   to violate a core property has found a bug in the core, and the right
   response is to fix the core rather than to special-case around it.

Most extensions will add `semantic_type` rows under existing
`semantic_family` values. Some will add a new family. Very few should touch
`data_type`.

## Extension has a cost, and it is measurable

Adding a node is not free, and the framework makes the price visible rather
than leaving it as a vague concern:

- Every new `semantic_type` needs banked examples spanning easy, medium, and
  hard before it can be scored at all.
- Every new node adds pairs to the confusion weighting, and the `hidden_risk`
  report will surface any it is genuinely confusable with — sometimes nodes
  nobody expected.
- The guessability test applies to extension nodes exactly as it does to core
  ones. A domain distinction that matters professionally but is invisible in
  the values does not become detectable by being important.

This is the discipline that keeps extensibility from becoming sprawl. An
extension author cannot simply assert a type; they have to demonstrate it is
separable.

## Lifecycle: revision, deprecation, retirement

The lifecycle columns exist to serve change. They are what make an extensible
ontology safe to extend, because they let a growing vocabulary evolve without
invalidating work already done against it.

```
version_added        the ontology version where this row first appeared
version_deprecated   set INSTEAD of deleting a row
superseded_by        semantic_type_id(s), ";;"-separated for splits
change_note          free text: what changed and why
```

**Rows are never deleted.** Set `version_deprecated` so a stale reference in an
old case file resolves to something that can explain itself, rather than
failing on a missing key. A retired node is still readable history.

Four kinds of change, with determinate blast radius:

| Change | Case impact | Scoring impact |
|---|---|---|
| **Rename** | none — the ID survives | none |
| **Merge** | mechanical relabel; keep the older ID, deprecate the other | recompute affected pairs |
| **Move** (reparent) | none — the ID survives | **all pairs** — `path_distance` changes for every pair involving the node, so sibling weights and the evaluation metric must be recomputed |
| **Split** | **mandatory re-review** — both fragments get new IDs, `superseded_by` points back to the retired parent | recompute affected pairs |

Track case impact and scoring impact as **separate columns**, because they
diverge: a move needs no relabeling but invalidates every score, while a merge
needs relabeling but barely touches scoring.

**Splits retire the parent.** This is the one place the framework accepts extra
re-review cost in exchange for exactness. Keeping the parent ID for the larger
fragment would be cheaper, but then some cases carrying that ID would be
correct and some would not, with nothing to distinguish them. A split means the
old label was ambiguous; retiring it says so honestly.

## What this buys

The combination — a small core, namespaced extensions, immutable IDs, and
deprecation instead of deletion — means the ontology can grow indefinitely in
domain-specific directions while:

- case libraries built against earlier versions stay valid,
- detectors trained on the core keep working unchanged,
- an extension in one domain never perturbs another,
- and the impact of any change is computable rather than estimated.

That is the actual design goal. Not completeness — **safe, auditable growth
from a core small enough to be worth trusting.**
