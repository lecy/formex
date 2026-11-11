# The Ontology

The **ontology** is the shared catalog at the center of `formex`: a
small, labeled map of every kind of column research data contains. Both
halves of the package read it —
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
to decide *where a column belongs*, and
[`fx_stabilize()`](https://lecy.github.io/formex/reference/fx_stabilize.md)
to look up *how to clean it*. This guide walks the map one **data type**
at a time.

## How the map is organized

Every entry sits at four levels of increasing specificity:

    data_type        how should it be treated?     number · text · temporal · ...
     └ semantic_family   what broad kind?           date · currency · geographic · ...
        └ semantic_type     what exactly?           calendar · usd · us_state · ...
           └ format_style / unit_type   how written / what unit?

The top level, **`data_type`**, is the load-bearing one: it decides
whether a column is a quantity you can do math on, a label you must
leave untouched, a point in time, and so on. The sections below are
organized by it. Each opens with what the type *is* and how it differs
from the types it is most often confused with, followed by the families
and semantic types inside it.

### The detector column

Not every type can be recognized just by looking at the values, and the
ontology is honest about which can. Each type records *how* it is
spotted, in a `match_kind` — shown as the **detector** column in every
table below:

| detector | spotted by |
|----|----|
| **`genome`** | a flexible date/time reader that tries many formats |
| **`mask`** | a fixed written shape, sometimes with a self-checking digit |
| **`lexicon`** | membership in a known list of allowed values |
| **`mask+lexicon`** | the right shape *and* a match in a known list |
| **`shape`** | the overall look of the numbers (range, decimals, sign) |
| **`none`** | cannot be told from the values alone — only a name or data dictionary can |

That last row matters for honesty. A membership-number column is just
integers; a notes column is just text. No amount of looking at the
values reveals what they are, so the ontology marks these `none` and the
engine does not pretend.

| data_type   | entries |
|:------------|--------:|
| boolean     |       5 |
| categorical |      13 |
| identifier  |      10 |
| number      |      23 |
| structured  |       6 |
| temporal    |      12 |
| text        |      25 |
| unknown     |       3 |

Those totals count geographic entries under their home data type
(coordinates under `number`, GEOIDs under `identifier`, and so on); the
final **Geography** section gathers them back together in one place.

------------------------------------------------------------------------

## `number` — quantities you can do math on

A `number` is a magnitude: something you can meaningfully add, average,
or compare. This is the type to get right first, because it licenses
arithmetic.

**Not to be confused with `identifier`.** A ZIP code, a county FIPS, and
an account number are all written with digits, but they are *labels*,
not magnitudes — averaging them is nonsense and dropping their leading
zeros corrupts them. If digits are a quantity, they are a `number`; if
they are a key, they are an `identifier`. The `currency` family carries
a `unit_type`, because the same written number can mean dollars or
euros. Geographic **coordinates** are numbers too — a lat/lon pair is a
measurement on a datum — but they are gathered with the rest of
geography in the Geography section at the end.

[TABLE]

## `text` — strings, from free prose to structured tokens

`text` covers values whose content is characters: names, email
addresses, URLs, colors, and free-form notes. (Place names and postal
addresses are geographic text, gathered in the Geography section at the
end.) Some text is highly structured (an email, a hex color) and gets a
scheme-specific recipe; some is genuinely free (`text.long`) and is
simply preserved.

**Not to be confused with `categorical`.** A `text` column’s values are
open-ended — a new row can introduce a name or note never seen before. A
`categorical` column draws from a *fixed, closed* set of levels. “City
name typed in freely” is text; “one of five survey response options” is
categorical.

| family | semantic_type | meaning | formats / units | detector |
|:---|:---|:---|:---|:---|
| color | **cmyk** | A CMYK quadruple. | `cmyk` | `mask` |
| color | **color_name** | A named color (word), e.g. a hair or eye color. | `color_name` | `lexicon` |
| color | **hex** | A hex color. | `hex` | `mask` |
| color | **hsl** | An HSL triple. | `hsl` | `mask` |
| color | **rgb** | An RGB triple. | `rgb` | `mask` |
| contact | **email** | An email address. | `email` | `mask` |
| contact | **phone** | A phone number. | `phone` | `mask` |
| name | **handle** | A social / user handle. | `handle` | `lexicon` |
| name | **organization** | An organization’s name. | `organization` | `lexicon` |
| name | **person** | A person’s name. | `first_name`, `last_name`, `full_name` | `lexicon / mask+lexicon` |
| text | **label** | A short human label. | `label` | `none` |
| text | **literal** | Preserve raw data as-is. | `literal` | `none` |
| text | **long** | Long free text. | `long` | `none` |
| text | **serialized** | Serialized text (JSON/XML/delimited). | `serialized` | `none` |
| text | **title** | A title or heading. | `title` | `none` |
| web | **domain** | A domain / hostname. | `domain` | `mask` |
| web | **ip** | An IP address. | `ip` | `mask` |
| web | **mac** | A MAC address. | `mac` | `mask` |
| web | **url** | A URL. | `url` | `mask` |
|  | *\* geographic* | *place names and postal addresses are text — see the Geography section below* |  |  |

## `temporal` — points and spans in time

`temporal` values live on a timeline: a calendar date, a timestamp, a
quarter, a day-of-week. They are detected by a flexible reader
(`genome`) that recognizes many written forms and normalizes them to
ISO. The `period` and `phase` families cover coarser or cyclic time (a
fiscal quarter, a month-of-year), where a `unit_type` such as the fiscal
convention can matter.

**Not to be confused with `number`.** `2019` could be a count or a year;
`3.15` could be a measurement or a fragment of a date. What makes a
column `temporal` is that its values *locate something in time*, which
the reader confirms by parsing them as such.

[TABLE]

## `categorical` — a value from a fixed set of levels

A `categorical` column takes one value from a closed vocabulary: a
Likert response, a classification code, a set of tags. The
level-to-label mapping lives in a dictionary alongside the data; the
ontology records only the *shape* of the encoding.

**Not to be confused with `boolean` or `text`.** A `boolean` is the
special case of exactly two levels that mean true/false. Free strings
with no fixed set are `text`. Many categorical types are
`none`-detected: a column of codes `1, 2, 3` cannot be told from a count
without its labels.

[TABLE]

## `boolean` — a two-state flag

A `boolean` is a yes/no, true/false, present/absent flag. `formex`
recognizes a wide vocabulary of encodings (`yes/no`, `t/f`, `1/0`,
`active/inactive`, a bare `x` check) and maps them all to
`TRUE`/`FALSE`.

**Not to be confused with `categorical`.** A boolean is *exactly* two
states that collapse to logical true/false. Three or more mutually
exclusive levels are categorical. The one thing that cannot be defaulted
is the blank policy — a blank is *missing* in a survey but *FALSE* in a
checkbox — so the encoding records it explicitly.

| family | semantic_type | meaning | formats / units | detector |
|:---|:---|:---|:---|:---|
| binary | **indicator** | A 0/1 indicator flag. | `indicator` | `mask` |
| binary | **mixed** | A mixed-encoding boolean (e.g. IRS 990). | `mixed` | `mask` |
| binary | **presence** | A present/absent (checkbox) flag. | `presence` | `mask` |
| binary | **response** | A yes/no survey response. | `response` | `mask` |
| binary | **status** | An on/off status. | `status` | `mask` |

## `identifier` — keys and codes that must be preserved exactly

An `identifier` labels something: an EIN, an ISBN, a DOI, a record key,
a geographic GEOID (see the Geography section at the end). The defining
rule is that its written form *is* the data — leading zeros, delimiters,
and check digits all matter — so it must never be coerced to a number or
silently reformatted.

**Not to be confused with `number`.** This is the most consequential
distinction in the whole ontology, because treating an identifier as a
number is how real data gets corrupted (`06037` → `6037`). Identifiers
are detected by `mask` (a fixed shape, often with a checksum) and
sometimes a `lexicon` of valid codes; `record` and `entity` keys are
`none`, knowable only from context.

| family | semantic_type | meaning | formats / units | detector |
|:---|:---|:---|:---|:---|
| id | **administrative** | An administrative / registry ID. | `ein`, `isbn`, `doi`, `orcid`, `issn` | `mask` |
| id | **entity** | An entity identifier. | `entity` | `mask` |
| id | **hash** | A hash digest. | `hash` | `mask` |
| id | **record** | A record / row key. | `record` | `mask` |
| id | **version** | A version identifier. | `version` | `mask` |
|  | *\* geographic* | *geographic keys (FIPS / GEOID) are identifiers — see the Geography section below* |  |  |

## `structured` — composite values with internal parts

A `structured` value packs more than one field into a single cell: a
JSON object, a WKT geometry (geographic geometries are gathered in the
Geography section at the end), an array, a key-value blob. It is
detected by the syntax of the container and is typically handled by
parsing or splitting into component variables.

**Not to be confused with `categorical` tags.** A `multiselect` tag list
is a flat set of labels; a `structured` value has real internal syntax
(brackets, braces, coordinates) that a parser must honor.

[TABLE]

## `unknown` — the honest fallback

`unknown` is where a column lands when the values cannot support any
type: a column mixing dates, numbers, and prose (`heterogeneous`), a
column of corrupt values (`malformed`), or one that simply did not
resolve (`unclassified`). It is deliberately part of the ontology, so
the engine always has a safe, truthful place to stop rather than forcing
a wrong guess.

| family | semantic_type | meaning | formats / units | detector |
|:---|:---|:---|:---|:---|
| unknown | **heterogeneous** | A column mixing several data types. | `heterogeneous` | `none` |
| unknown | **malformed** | Malformed / parse-failure values. | `malformed` | `none` |
| unknown | **unclassified** | Unclassified values. | `unclassified` | `none` |

------------------------------------------------------------------------

## `geography` — a cross-cutting domain, not a data type

Geography is the one case that deliberately does **not** get its own
`data_type`, and it is worth saying why. The top level of the ontology
classifies *how a value should be treated, not what domain it is about*
— and a geographic value can need completely different handling
depending on the column it sits in. The *same place* can be three data
types at once: `"Los Angeles County"` the **label**, `06037` the
**key**, and `34.3, -118.2` the **coordinate**.

So geographic entries are distributed across the data types above. Here
they are gathered in one place, with a `data_type` column so the split
is explicit:

[TABLE]

Why each case lands where it does:

- **`number` — coordinates.** A latitude/longitude pair is a
  *measurement* on a datum (its `unit_type` is a coordinate reference
  system such as EPSG:4326). You interpolate it, compute distances,
  reproject it — all arithmetic — so it is a number.
- **`identifier` — geographic keys.** A FIPS or GEOID like `06037` is a
  *key* you join on. Its leading zero and fixed width are load-bearing,
  so it must stay text and is hardened (`FIPS-06037`) against a
  spreadsheet silently turning it into `6037`. Taking its average is
  meaningless.
- **`categorical` — groupings.** A state or country used to *group* rows
  (`us_state`, `iso_country`) is a factor you analyze *by*: a closed
  vocabulary, matched against a lexicon.
- **`text` — place names and addresses.** A freely typed city name or a
  street address is open-ended text — a new row can introduce one never
  seen before — so it is handled as text, not as a closed category.
- **`structured` — geometries.** A WKT point or polygon packs
  coordinates into a single cell with real internal syntax that a parser
  must honor.

So when you meet a geographic column, the useful question is not “is
this geography?” but “which **treatment** does it need?” — and the
answer places it under the matching data type, with that type’s recipe
for cleaning and storing it.

------------------------------------------------------------------------

## Stable identities, so a label means the same thing next year

Every entry carries a stable `semantic_type_id` (like `n0059`) and
`variant_id` (like `n0059-f01`) that are assigned once and never reused.
Types are *retired* rather than deleted, so a label you record today
still means the same thing years from now.
[`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)
reads the whole map;
[`fx_validate_ontology()`](https://lecy.github.io/formex/reference/fx_validate_ontology.md)
checks it is internally consistent.

## Where to go next

- **Guess Data Type** — how a column is walked down this tree, and why
  the walk is allowed to stop early.
- **Formatting Syntax** — the recipe each leaf stores for cleaning and
  safely storing its column, and how to add your own. \`\`\`
