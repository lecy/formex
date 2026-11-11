# Feature Engineering for Type Guessing

When
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
looks at a column, part of the work is done by detectors (see *How
Detectors Recognize a Type*). But the first stage — the **router** that
proposes which types are even worth checking — is a trained model, and a
model cannot read raw strings. It needs numbers. So before anything is
guessed, the column is turned into a fixed list of numbers that
*summarize* it: its **feature profile**. Building that profile is called
**feature engineering**, and this guide explains what goes into it and
what it can and cannot capture.

## The idea: describe a column with numbers

Think about how *you* tell an ID column from a name column at a glance.
You don’t read every value — you notice things: the ID values are all
the same length, all digits, every one different; the names are words,
start with a capital, repeat, and many are ones you recognize. Feature
engineering writes down those impressions as numbers.

[`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md)
does this. Give it a column and it returns one row of summary numbers:

``` r

f <- fx_extract_features(c("James", "Mary", "Robert", "Linda", "James"))
dim(f)       # one row of features for the whole column
#> [1]   1 477
f[c("n", "n_unique", "unique_ratio", "len_mean", "pct_chr_alpha", "lex_first_name_token")]
#>   n n_unique unique_ratio len_mean pct_chr_alpha lex_first_name_token
#> 1 5        4          0.8        5             1                    1
```

Read that row as the model would: five values, four distinct, all
letters, and — the giveaway — every one is a known first name
(`lex_first_name_token` is `1`). That last number alone almost settles
it.

Every column, whatever its contents, is reduced to the **same** fixed
set of numbers, so the router can compare any column against the
patterns it learned during training.

## What goes into the profile

The numbers are organized into **blocks**, each capturing a different
kind of signal. Here is the live inventory from the installed package:

``` r

man <- fx_feature_manifest()
as.data.frame(table(block = man$block), responseName = "n_features")
#>        block n_features
#> 1  charclass         22
#> 2   charfreq         97
#> 3       core         21
#> 4     header         20
#> 5     length         23
#> 6    lexicon         30
#> 7       mask         21
#> 8    numeric         48
#> 9      punct        118
#> 10     regex         43
#> 11  sequence         11
#> 12     token         23
```

That is 477 numbers in all. What each block is looking at, in plain
terms:

- **core** — the column’s shape as a whole: how many values, how many
  are missing, how many are *distinct*, whether every value is unique (a
  strong hint for an ID), whether one value dominates. This is the “is
  it a key? a constant? a handful of repeated categories?” signal.
- **length** — how long the values are, and how much the length
  *varies*. IDs and codes are often all one length; names and addresses
  vary a lot.
- **charclass** — the mix of character kinds: what share are letters,
  digits, punctuation, whitespace, uppercase.
- **charfreq** — the frequencies of individual letters and digits,
  including the **first** and **last** character distributions. This is
  surprisingly powerful: the last letter of a word carries morphology
  (names ending in *-a*, *-n*), and leading characters separate, say,
  `B0`-prefixed product codes from ordinary text.
- **punct** — where and how often punctuation appears (and how
  regularly). A phone number, a date, and an IP address each have a
  signature arrangement of separators.
- **token** — structure when values are split into words/pieces: how
  many tokens, and whether the first and last token are stable across
  the column (the word-level version of fixed punctuation).
- **mask** — how well the values fit fixed positional shapes (the
  digit/letter templates the `mask` detectors use).
- **regex** — hit rates against a battery of pattern probes.
- **numeric** — when values are numbers: their range, whether they are
  whole, signed, bounded 0–1, their spread and skew. This is the block
  the `shape` types lean on.
- **sequence** — run-length and ordering signals (e.g. values that look
  like a sequential counter).
- **lexicon** — the share of values that appear in built-in reference
  lists: common first names, surnames, US cities, countries, states.
  These membership rates are among the **strongest** signals the router
  has for telling the easily-confused people/place columns apart.
- **header** — features of the column’s *name*, when one is supplied,
  for the cases where the values are silent.

Blocks are computed independently, so the engine can skip ones a given
model does not use. Missing or not-applicable numbers are recorded as
`NA`, never as zero, so “no digits here” is never confused with “a digit
value of zero.”

## From profile to shortlist

The feature profile feeds the **router**, which proposes a short list of
likely types. Two routers ship:

- a **learned** model (gradient-boosted trees) trained on thousands of
  labeled columns’ profiles — the default when it is installed;
- a **signature** router that needs no model: it reduces the profile to
  a short numeric fingerprint and ranks ontology types by how close
  their known examples sit to the column.

Either way the profile is the input. The verifier stage then confirms
the shortlist’s candidates with their actual recipes (see *Guessing a
Column’s Type*), so a feature-based shortlist never gets the final word
by itself.

## Where it works well — and where it struggles

The honest summary: **the model is only as good as the signal the values
carry.** Where a type leaves a fingerprint in how its values are
written, feature-based guessing is excellent. Where two types look
identical as values, no amount of feature engineering can separate them.

**Works well** (the structure is in the values):

- **Dates and times** — the parse either succeeds or it doesn’t;
  recognition is near-perfect.
- **Names and geographies** — the lexicon-membership features are
  decisive: a column of values that are mostly known first names is
  almost unmistakable.
- **Shaped identifiers** — EINs, ISBNs, UUIDs, hashes: fixed length,
  fixed alphabet, often a checksum.

**Struggles** (the signal is not in the values):

- **Numeric subtypes.** A *count*, a *score*, an *index*, and a *rate*
  are all just numbers. The `numeric` block can say “this is a bounded
  whole number,” but it cannot say *which* kind of quantity it is — that
  needs the column name or a codebook. The router sensibly keeps these
  columns shallow rather than guessing a leaf.
- **Surrogate / record keys.** A membership ID is a column of unique
  integers, which looks like any other column of unique integers. The
  `core` block flags “this is probably a key,” but it cannot say *what
  entity* it keys.
- **Free text.** Notes and descriptions have no recognizable form.
- **Unfamiliar data.** On data unlike anything the model trained on, it
  is far better at the broad call (“this is a number / a date / a code”)
  than at the exact leaf. Measured on an outside corpus during
  development, the model’s confidence in the broad `data_type` held
  around **0.70** while its confidence in the exact leaf fell to about
  **0.48** — which is exactly why
  [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
  reports a path *prefix* and stops early rather than forcing a precise
  but unreliable leaf.

As a development benchmark (3-fold out-of-fold on roughly 3,850 labeled
columns, measured during model fitting and not recomputed here), the
learned router placed the correct type in its top choice about **77%**
of the time and in its top five about **94%** — with the easy families
(dates, names) near-perfect and the value-undetectable ones (numeric
subtypes, record keys) carrying the misses. The strongest single
feature, by a wide margin, was the first-name lexicon-membership rate —
a reminder that a good reference list often beats a clever statistic.

## See also

- **How Detectors Recognize a Type** — the per-value recognizers the
  profile works alongside.
- **Guessing a Column’s Type** — the router → verifier flow the profile
  feeds.
- [`fx_extract_features()`](https://lecy.github.io/formex/reference/fx_extract_features.md),
  [`fx_feature_manifest()`](https://lecy.github.io/formex/reference/fx_feature_manifest.md),
  and
  [`fx_type_signature()`](https://lecy.github.io/formex/reference/fx_type_signature.md)
  — the profile, its catalogue, and the model-free fingerprint.
