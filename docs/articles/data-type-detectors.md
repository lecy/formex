# Data-Type Detector Guide

## Detectors recognize a *format*, not just a type

`formex` ships a library of **detectors**: small functions that answer
one yes/no question about a column — *“is each value written in format
X?”* Each is a pure predicate:

- **input:** a character vector `x`
- **output:** a logical vector the same length (`TRUE` where the value
  matches, `NA` where `x` is `NA`); detectors never error.

The word *format* is doing the work here. “Is this a date?” is too loose
to be useful — almost any short string of digits and slashes could be a
date. The detector that earns its place answers something tighter: *is
this a `M/D/YYYY` date, with the month first, slashes as separators, and
real month and day numbers?* That is a **format style**: a specific
written shape, with its delimiters in specific places, drawn from a
specific alphabet, often of a specific length, sometimes carrying a
self-checking digit. A detector is good exactly when it pins that
structure and rejects everything that merely resembles it.

## Stress-testing the format with AutoType

So the hard part is not accepting real values — it is **rejecting
plausible-but-wrong ones** that share the data type but break the
format. To measure that, `formex` borrows the negative-example machinery
from the **AutoType** framework (Yan & He, *Auto-Type: Synthesizing
Type-Detection Logic …*, SIGMOD 2018), which synthesizes type detectors
and the hard negatives to test them. Starting from a handful of real
positives, it mutates them into near-misses along four tiers — each one
aimed at a different part of the format’s structure:

| Tier | Name | What it changes | The structure it stresses |
|----|----|----|----|
| **S1** | preserve-structure | replaces only alphanumeric characters, leaving the delimiters in place | the *alphabet / values* (for loose types it often regenerates a valid value, so it stresses little) |
| **S2** | preserve-alphabet | replaces any character, but only with characters seen in real examples | the *arrangement*, while staying in-vocabulary |
| **S3** | random | replaces characters with arbitrary printable ASCII | the *alphabet* itself (the easiest negatives) |
| **SP** | scramble-structure | keeps the alphanumerics and their order, but **permutes where the punctuation/delimiters sit** | the *format style directly* — a decimal point, a grouping comma, a symbol in the wrong position |

That last tier, **SP**, is the point of this guide’s framing: it holds
the data type constant and attacks only the *format style*, catching a
detector that checks “the right characters are present” but not “in the
right places.” In that sense the fixtures test **formats more than they
test types.**

The frozen mix of valid + labelled negatives is the bundled
\[`data_type_tests`\] object. The report below applies each detector to
it and reports **pass rates** per tier:

- **Recall** — share of real positives accepted. Should be **1.00**.
- **S1 / S2 / S3 / SP** — share of generated near-misses *wrongly*
  accepted (a false-positive rate). Lower is better; blank means that
  tier produced no distinct negatives. A **high S1 is expected** for
  loose formats (mutating the digits of `"$12.30"` to `"$47.99"` is
  still a valid amount) — read S2/S3/SP for those.

## What structure a detector leverages

Every detector in the catalogue names its **strategy** — the structure
in the data it keys on. There are a handful of recurring kinds, from
loosest to tightest:

- **exact lookup** — the value must be a member of a closed reference
  set (ISO currency codes, USPS states, NAICS codes). The structure *is*
  the list.
- **small enum** — a lookup against a short fixed vocabulary (census
  regions, NCES locales).
- **structured regex** — a positional shape: delimiters and character
  classes in fixed places (`EIN` = two digits, a dash, seven digits; a
  `GUID` = the 8-4-4-4-12 hex pattern). This is where the SP tier bites
  hardest.
- **regex + range** — a shape *plus* a numeric bound, so the parts have
  to be real (an IPv4 octet is 0-255; an ISO date’s month is 1-12).
- **anchor + length** — a fixed width whose prefix must be valid (a
  county FIPS is five digits whose first two are a real state code).
- **checksum** — the value validates its own check digit (ISBN, ORCID,
  NPI, DEA), so a single wrong character is caught arithmetically. The
  tightest structure available.
- **heuristic / composite** — for loose real-world text (addresses),
  fires when several weaker components co-occur.

The catalogue below lists the detectors that ship with a frozen AutoType
fixture, grouped by family, each with its one-line definition, the
**strategy** (the structure it leverages), real examples, and the
stress-test report. (A few newer detectors —
[`is_currency_amount()`](https://lecy.github.io/formex/reference/is_currency_amount.md),
[`is_version()`](https://lecy.github.io/formex/reference/is_version.md),
[`is_boolean()`](https://lecy.github.io/formex/reference/is_boolean.md),
the phase and geometry detectors — are wired into the ontology but not
yet in this frozen fixture, so they are not reported here.)

## The catalogue

### Currency

#### `is_currency_code()`

ISO 4217 three-letter alphabetic currency code (USD, EUR, JPY).

**Precision:** exact lookup\
**Strategy:** Upper-cases the value and tests membership in the ISO 4217
code list.\
**Examples:** `AUD`, `CAD`, `CNY`, `DKK`, `EUR`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.011 | 0.011 | 0.006 |  NA |

#### `is_currency_symbol()`

A currency symbol immediately followed by an amount, e.g. \$12.30.

**Precision:** structured regex\
**Strategy:** Regex: a leading symbol (\$ euro yen pound) + digits +
optional 1-2 decimals.\
**Examples:** `$12.30`, `€299.10`, `¥19`, `£1222`, `$1`

| Recall |  S1 |    S2 |    S3 |    SP |
|-------:|----:|------:|------:|------:|
|      1 |   1 | 0.257 | 0.013 | 0.049 |

#### `is_currency_code_symbol()`

An ISO code, symbol, and amount together, e.g. USD\$12.30.

**Precision:** regex + lookup\
**Strategy:** Regex for code+symbol+amount, then validates the 3-letter
code against ISO 4217.\
**Examples:** `USD$12.30`, `EUR€299.10`, `USD$1`, `EUR€21`, `JPY¥22`

| Recall |    S1 |    S2 |  S3 |    SP |
|-------:|------:|------:|----:|------:|
|      1 | 0.029 | 0.008 |   0 | 0.019 |

### Web / network

#### `is_email()`

An email address.

**Precision:** structured regex (loose)\
**Strategy:** Regex: local part + @ + dotted domain + TLD; pragmatic,
not full RFC 5322.\
**Examples:** `cjudgkins0@de.vu`, `csoutar1@bigcartel.com`,
`afeavearyear2@skype.com`, `fmacgilrewy3@yellowpages.com`,
`aeadmeades4@tamu.edu`

| Recall |   S1 |   S2 |   S3 |    SP |
|-------:|-----:|-----:|-----:|------:|
|      1 | 0.68 | 0.15 | 0.01 | 0.434 |

#### `is_url()`

An http/https/ftp URL.

**Precision:** structured regex\
**Strategy:** Regex: scheme :// + dotted host + optional path/query.\
**Examples:** `http://ezproxy.baylor.edu/`,
`https://www.ezproxy.unibo.it/`, `http://ezproxy.anzca.edu.au/`,
`http://libproxy.aalto.fi/`, `http://elibrary.einstein.yu.edu/`

| Recall |    S1 |   S2 |  S3 |    SP |
|-------:|------:|-----:|----:|------:|
|      1 | 0.067 | 0.01 |   0 | 0.034 |

#### `is_ipv4()`

An IPv4 dotted-quad address.

**Precision:** regex + range\
**Strategy:** Regex for four numeric octets, then validates each is
0-255.\
**Examples:** `54.219.219.166`, `49.200.88.156`, `189.7.190.3`,
`206.120.6.24`, `80.78.48.54`

| Recall |    S1 |    S2 |    S3 |   SP |
|-------:|------:|------:|------:|-----:|
|      1 | 0.421 | 0.077 | 0.003 | 0.06 |

#### `is_ipv6()`

An IPv6 address (full or ::-compressed).

**Precision:** structured regex\
**Strategy:** Regex over eight hex groups plus common :: compressions.\
**Examples:** `89a4:e654:d143:d1d0:b986:73e4:c8e1:4710`,
`f385:9ac0:aede:bb7e:a620:b2a5:dd6b:ebfb`,
`4f:45b6:3366:d336:e41b:8df4:696:e02`,
`8316:886e:bebc:738:e0e0:215f:89de:89fb`,
`70eb:2fd0:84c2:9abd:7682:ff5b:afff:c24d`

| Recall |  S1 |    S2 |  S3 |  SP |
|-------:|----:|------:|----:|----:|
|      1 |   1 | 0.005 |   0 |   0 |

#### `is_mac()`

A MAC hardware address.

**Precision:** structured regex\
**Strategy:** Regex: six colon- or dash-separated hex octet pairs.\
**Examples:** `40-1F-3C-B6-3C-BC`, `1E-42-64-5E-54-69`,
`1F-9C-F0-33-2E-E5`, `22-1F-8C-02-75-1D`, `9B-D7-6F-02-9F-D5`

| Recall |  S1 |    S2 |  S3 |  SP |
|-------:|----:|------:|----:|----:|
|      1 |   1 | 0.025 |   0 |   0 |

### Color

#### `is_hex_color()`

A hex color such as \#4d9cf8 or \#fff.

**Precision:** structured regex\
**Strategy:** Regex: \# + 3 or 6 hex digits.\
**Examples:** `#4d9cf8`, `#1f3a8e`, `#eac3aa`, `#dc937b`, `#2cb0c3`

| Recall |  S1 |   S2 |    S3 |  SP |
|-------:|----:|-----:|------:|----:|
|      1 |   1 | 0.44 | 0.024 |   0 |

#### `is_rgb_color()`

An RGB triple such as 220,220,220.

**Precision:** regex + range\
**Strategy:** Three comma-separated integers, each validated 0-255.\
**Examples:** `220,220,220`, `255,250,250`, `253,245,245`,
`240,240,240`, `250,235,235`

| Recall |    S1 |   S2 |    S3 |    SP |
|-------:|------:|-----:|------:|------:|
|      1 | 0.315 | 0.07 | 0.004 | 0.035 |

#### `is_hsl_color()`

An HSL triple such as 195, 100%, 27%.

**Precision:** regex + range\
**Strategy:** Hue validated 0-360 and two percentages 0-100.\
**Examples:** `195, 100%, 27%`, `195, 100%, 47%`, `196, 60%, 49%`,
`197, 72%, 55%`, `200, 29%, 55%`

| Recall |    S1 |  S2 |  S3 |    SP |
|-------:|------:|----:|----:|------:|
|      1 | 0.506 |   0 |   0 | 0.039 |

#### `is_cmyk_color()`

A CMYK quadruple such as 0.0,0.31,0.37,0.0.

**Precision:** regex + range\
**Strategy:** Four comma-separated values, each validated 0-1.\
**Examples:** `0.0,0.31,0.37,0.0`, `0.0,0.52,1.0,0.64`,
`0.35,0.0,0.25,0.0`, `0.52,0.63,0.48,0.0`, `0.30,0.6,0.0,0.0`

| Recall |    S1 |  S2 |  S3 |    SP |
|-------:|------:|----:|----:|------:|
|      1 | 0.097 |   0 |   0 | 0.009 |

### Hash / UUID

#### `is_md5()`

An MD5 message digest.

**Precision:** fixed-length regex\
**Strategy:** Exactly 32 hexadecimal characters.\
**Examples:** `6e8a6448a62364225da9991fd8e1ef8c`,
`3df4ffb6eb24fffab3763041f13dbdea`, `b205e37bafd229efeb6345565ce428a0`,
`d604c1cd26544a8c30f0bb20a689eac7`, `793fce16a0a172e58c193b2899e0c025`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   1 |   1 |   0 |  NA |

#### `is_sha1()`

A SHA-1 message digest.

**Precision:** fixed-length regex\
**Strategy:** Exactly 40 hexadecimal characters.\
**Examples:** `16de70e8fcd093964a448a86bc89b1c607152ead`,
`efb6759998e36322258c172aa7e8ba6416b3235f`,
`f1d48e18f51de36d01bafab5bfa68d16a8c0192b`,
`0ceee2d04e239856ecf18f93b5ee75d72e031f92`,
`ac8a1226405cab9d6049304163d658c5ae611c1a`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   1 |   1 |   0 |  NA |

#### `is_sha256()`

A SHA-256 message digest.

**Precision:** fixed-length regex\
**Strategy:** Exactly 64 hexadecimal characters.\
**Examples:**
`96a162ea0e727b109724d95fa66659aacc2f5a1478c12bb779aa9c1fbd510450`,
`59d3b1aafad9d120e6df4a1a6ae6b5edf006be7a044e646b63a9feb8e909c900`,
`18f778c3525b95d98292595ebd8a0c5ac31bfb6cddeafefff04089468e304b96`,
`e93042fecce04326c178d34b88c70f3ef8e90aaaefbc14e53a17a772c149b113`,
`21995f09908d3bb4f2c7eaf99a50cbad991aeb652208bb71c55e3161fcfaa493`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   1 |   1 |   0 |  NA |

#### `is_guid()`

A GUID / UUID.

**Precision:** structured regex\
**Strategy:** The 8-4-4-4-12 hexadecimal UUID pattern.\
**Examples:** `f2a59360-1d1a-49e8-9a2f-f9cdf0d5a811`,
`5ff3cc50-709c-4ba2-88a7-a2e4cca9f32c`,
`241c3e6c-1aa5-41c6-bbac-8ad08bdfcde9`,
`12e8b5a7-a1be-4dec-933a-6f9b040f8da3`,
`2eddc761-2258-4305-9e7b-c1087df3165c`

| Recall |  S1 |    S2 |  S3 |  SP |
|-------:|----:|------:|----:|----:|
|      1 |   1 | 0.035 |   0 |   0 |

### Scientific / bio IDs

#### `is_ensembl_id()`

An Ensembl gene/transcript/protein ID (ENSG…, ENSMUSG…).

**Precision:** structured regex\
**Strategy:** Regex: ENS + optional species + feature letter (E/G/T/P) +
11 digits.\
**Examples:** `ENSMUSG00000102659`, `ENSMUSG00000093178`,
`ENST00000407559`, `ENSG00000139618`, `ENSG00000158636`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |  NA |

#### `is_uniprot_id()`

A UniProtKB protein accession (P33667, Q9BWD1).

**Precision:** structured regex\
**Strategy:** The official UniProt accession-number pattern.\
**Examples:** `P33667`, `P17888`, `P02338`, `Q9BWD1`, `Q46806`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.311 | 0.311 | 0.017 |  NA |

#### `is_icd9_code()`

An ICD-9-CM diagnosis code.

**Precision:** structured regex\
**Strategy:** Regex: three digits (or an E/V code) + optional decimal
detail.\
**Examples:** `078.11`, `008.8`, `005.9`, `117.9`, `003.0`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.652 | 0.294 | 0.013 |   0 |

#### `is_icd10_code()`

An ICD-10 code (I61, D76.0).

**Precision:** structured regex\
**Strategy:** Regex: a letter + two digits + optional dotted detail.\
**Examples:** `I61`, `I63`, `G45`, `D76.0`, `D76.3`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.399 | 0.242 | 0.036 |   0 |

#### `is_snp_id()`

A dbSNP reference SNP ID (rs3918290).

**Precision:** structured regex\
**Strategy:** Regex: rs followed by digits.\
**Examples:** `rs3918290`, `rs1801159`, `rs1801265`, `rs17376848`,
`rs1801160`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.139 | 0.139 |   0 |  NA |

#### `is_asin()`

An Amazon Standard Identification Number.

**Precision:** structured regex\
**Strategy:** Regex: B0 followed by eight alphanumerics.\
**Examples:** `B01L7DYXL0`, `B0065RHC2Q`, `B004M8T1XS`, `B004M8T30O`,
`B0065RRJGK`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.262 | 0.262 | 0.013 |  NA |

#### `is_bibcode()`

A 19-character NASA ADS bibliographic code.

**Precision:** structured regex\
**Strategy:** Regex: 4-digit year + 14 code characters + a final
letter.\
**Examples:** `2004PASP..116...98K`, `2003ApJ...597..957H`,
`2003A&A...405..175M`, `2003ApJ...590..895W`, `2003A&A...404..249B`

| Recall |    S1 |    S2 |    S3 |    SP |
|-------:|------:|------:|------:|------:|
|      1 | 0.175 | 0.179 | 0.017 | 0.521 |

### Codes / lookups

#### `is_roman()`

A Roman numeral.

**Precision:** structured regex\
**Strategy:** The canonical well-formed Roman-numeral regex (rejects
e.g. IIII).\
**Examples:** `I`, `II`, `III`, `IV`, `V`

| Recall |    S1 |    S2 |   S3 |  SP |
|-------:|------:|------:|-----:|----:|
|      1 | 0.248 | 0.248 | 0.01 |  NA |

#### `is_http_status()`

An HTTP status code.

**Precision:** regex + range\
**Strategy:** Three digits within 100-599.\
**Examples:** `100`, `101`, `200`, `201`, `202`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.701 | 0.701 | 0.015 |  NA |

#### `is_unix_time()`

A Unix epoch timestamp in seconds.

**Precision:** regex + range (loose)\
**Strategy:** 9-10 digits within a plausible epoch range; inherently
loose.\
**Examples:** `1513036980`, `1503296497`, `1451638800`, `1360228214`,
`1497917283`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.996 | 0.996 | 0.004 |  NA |

#### `is_zip_code()`

A US ZIP or ZIP+4 code.

**Precision:** structured regex\
**Strategy:** Five digits, optionally + four.\
**Examples:** `98052`, `15206`, `32792`, `50613`, `27292`

| Recall |  S1 |    S2 |    S3 |  SP |
|-------:|----:|------:|------:|----:|
|      1 |   1 | 0.743 | 0.019 |   0 |

#### `is_uk_postcode()`

A UK postcode.

**Precision:** structured regex\
**Strategy:** The standard UK postcode outward/inward pattern.\
**Examples:** `SA43 2BU`, `PO12 2DU`, `KA20 3LN`, `MK43 7TA`, `DT4 8US`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.258 | 0.109 | 0.046 |   0 |

#### `is_ca_postal_code()`

A Canadian postal code or 3-character FSA.

**Precision:** structured regex\
**Strategy:** Letter-digit-letter, optionally followed by
digit-letter-digit.\
**Examples:** `V5K`, `K0H`, `T4A`, `T4B`, `T9S`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.279 | 0.233 | 0.152 |   0 |

#### `is_us_state()`

A USPS two-letter state code.

**Precision:** exact lookup\
**Strategy:** Membership in the 50 states + DC.\
**Examples:** `WA`, `OH`, `DC`, `NY`, `PA`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.059 | 0.059 | 0.057 |  NA |

#### `is_country_code()`

An ISO 3166-1 alpha-2 country code.

**Precision:** exact lookup\
**Strategy:** Membership in the ISO 3166-1 code list.\
**Examples:** `MA`, `AR`, `GR`, `CD`, `KP`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.467 | 0.467 | 0.216 |  NA |

### Date / time

#### `is_iso_date()`

An ISO 8601 calendar date (YYYY-MM-DD).

**Precision:** regex + range\
**Strategy:** Regex + a month/day range check.\
**Examples:** `2016-03-15`, `2016-03-13`, `2016-03-12`, `2016-03-11`,
`2020-01-01`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.337 | 0.085 |   0 |   0 |

#### `is_iso_datetime()`

An ISO 8601 datetime with optional fraction/zone.

**Precision:** structured regex\
**Strategy:** Regex over date + T + time + optional .fraction and
Z/offset.\
**Examples:** `1987-02-06T06:00:37`, `1988-01-12T06:34:58`,
`1930-07-06T02:08:45`, `2009-06-15T13:45:30`, `2010-06-15T13:45:30`

| Recall |    S1 |  S2 |  S3 |  SP |
|-------:|------:|----:|----:|----:|
|      1 | 0.165 |   0 |   0 |   0 |

#### `is_us_date()`

A US numeric date (M/D/YY).

**Precision:** regex + range\
**Strategy:** Regex + month/day validation.\
**Examples:** `3/3/16`, `1/27/16`, `12/31/99`, `7/4/2016`, `2/29/2020`

| Recall |    S1 |    S2 |  S3 |    SP |
|-------:|------:|------:|----:|------:|
|      1 | 0.615 | 0.125 |   0 | 0.032 |

#### `is_us_datetime()`

A US numeric datetime with AM/PM.

**Precision:** structured regex\
**Strategy:** Regex: M/D/YYYY (slash or dash) + time + optional AM/PM.\
**Examples:** `2/6/1987 6:00:37 AM`, `1/12/1988 6:34:58 AM`,
`7/6/1930 2:08:45 AM`, `7/15/1971 6:43:21 AM`, `05-13-2009 12:35 PM`

| Recall |    S1 |  S2 |  S3 |   SP |
|-------:|------:|----:|----:|-----:|
|      1 | 0.085 |   0 |   0 | 0.01 |

#### `is_abbr_month_date()`

Day-month-year with an abbreviated month (1-Jul-14).

**Precision:** structured regex\
**Strategy:** Regex: day + separator + 3-letter month + year.\
**Examples:** `1-Jul-14`, `2-Jul-14`, `3-Jul-14`, `4-Jul-14`,
`21/Nov/2012`

| Recall |   S1 |    S2 |  S3 |  SP |
|-------:|-----:|------:|----:|----:|
|      1 | 0.02 | 0.005 |   0 |   0 |

#### `is_rfc2822_datetime()`

An RFC 2822 / HTTP datetime.

**Precision:** structured regex\
**Strategy:** Regex: weekday, DD Mon YYYY hh:mm:ss + zone.\
**Examples:** `Fri, 06 Feb 1987 06:00:37 GMT`,
`Tue, 12 Jan 1988 06:34:58 GMT`, `Sun, 06 Jul 1930 02:08:45 GMT`,
`Thu, 15 Jul 1971 06:43:21 GMT`, `Mon, 01 Jan 2001 00:00:00 GMT`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

#### `is_long_date()`

A verbose English date (Friday, June 16, 1967).

**Precision:** structured regex\
**Strategy:** Regex allowing optional weekday, full/abbrev month, day,
year (with era) and time; requires a weekday or a year so it does not
overlap Month-Day.\
**Examples:** `Friday, June 16, 1967`, `Thursday, June 9, 1955`,
`Wednesday, May 17, 1967`, `Friday, June 16, 1967 8:46:44 AM`,
`Friday, February 6, 1987 2:00:37 PM`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

#### `is_month_year()`

A Month-Year value (February 1987).

**Precision:** structured regex\
**Strategy:** Regex: month name + optional comma + 4-digit year.\
**Examples:** `February 1987`, `January 1988`, `July 1930`, `July 1971`,
`August, 2005`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

#### `is_month_day()`

A Month-Day value with no year (February 6).

**Precision:** structured regex\
**Strategy:** Regex: month name + 1-2 digit day.\
**Examples:** `February 6`, `January 12`, `July 6`, `July 15`, `March 1`

| Recall |    S1 |  S2 |    S3 |  SP |
|-------:|------:|----:|------:|----:|
|      1 | 0.005 |   0 | 0.005 |   0 |

#### `is_clock_time()`

A clock time (6:00:37 AM).

**Precision:** regex + range\
**Strategy:** Regex + hour/minute range validation.\
**Examples:** `6:00:37 AM`, `6:34:58 AM`, `2:08:45 AM`, `6:43:21 AM`,
`11:59 PM`

| Recall |    S1 |   S2 |  S3 |  SP |
|-------:|------:|-----:|----:|----:|
|      1 | 0.115 | 0.02 |   0 |   0 |

#### `is_date_range()`

Two dates joined by ‘to’ or ‘-’.

**Precision:** structured regex\
**Strategy:** Regex over two ISO/US dates and a joiner.\
**Examples:** `07/21/16 to 08/19/16`, `08/20/16 to 09/20/16`,
`09/21/16 to 10/20/16`, `1972-01-01 - 1972-07-01`,
`1972-07-01 - 1973-01-01`

| Recall |    S1 |  S2 |  S3 |  SP |
|-------:|------:|----:|----:|----:|
|      1 | 0.144 |   0 |   0 |   0 |

#### `is_hijri_date()`

A Hijri (Islamic-calendar) date (11 Shawwal 1430).

**Precision:** structured regex\
**Strategy:** Regex: day + Islamic month name + year.\
**Examples:** `11 Shawwal 1430`, `5 Muharram 1300`, `19 Rajab 1460`,
`6 Muharram 1300`, `1 Ramadan 1445`

| Recall |    S1 |  S2 |  S3 |  SP |
|-------:|------:|----:|----:|----:|
|      1 | 0.006 |   0 |   0 |   0 |

### Address

#### `is_street_address()`

A street-address line (2325 140th St).

**Precision:** heuristic regex\
**Strategy:** Regex: house number + name + a street-type suffix
(St/Ave/Blvd/…).\
**Examples:** `2325 140th St`, `303 Aspen Ct`, `1225 S Walnut St`,
`30 Grandview Ct`, `100 Main St`

| Recall |    S1 |    S2 |    S3 |    SP |
|-------:|------:|------:|------:|------:|
|      1 | 0.013 | 0.013 | 0.003 | 0.047 |

#### `is_po_box()`

A PO box (PO Box 12, P.O.B. 3).

**Precision:** structured regex\
**Strategy:** Regex covering PO / POB / Post Office Box variants + a
number.\
**Examples:** `PO Box 1234`, `P.O. Box 56`, `POB 789`,
`Post Office Box 42`, `PO BOX 100`

| Recall |    S1 |   S2 |  S3 |    SP |
|-------:|------:|-----:|----:|------:|
|      1 | 0.025 | 0.01 |   0 | 0.073 |

#### `is_city_name()`

A US city / place name.

**Precision:** exact lookup (partial coverage)\
**Strategy:** Normalized membership test against ~1,000 larger US
cities; smaller towns miss by design (precision over recall).\
**Examples:** `Chicago`, `New Orleans`, `Springfield`, `Pittsburgh`,
`Bloomington`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

#### `is_city_state()`

A ‘City, State’ value.

**Precision:** regex + lookup\
**Strategy:** Splits on the comma and validates the trailing token is a
real state (abbrev or name).\
**Examples:** `Bloomington, IN`, `Cheshire, CT`, `Bloomington, Indiana`,
`Los Angeles, CA`, `New York, NY`

| Recall |   S1 |    S2 |   S3 |    SP |
|-------:|-----:|------:|-----:|------:|
|      1 | 0.31 | 0.062 | 0.05 | 0.307 |

#### `is_state_zip()`

A ‘State ZIP’ value.

**Precision:** regex + lookup\
**Strategy:** Regex whose leading token must be a real state, followed
by a ZIP.\
**Examples:** `IN 47401`, `CT, 06410`, `Indiana 47401`, `CA 90210`,
`TX 78701`

| Recall |   S1 |    S2 |  S3 |  SP |
|-------:|-----:|------:|----:|----:|
|      1 | 0.03 | 0.015 |   0 |   0 |

#### `is_address()`

A full postal address.

**Precision:** heuristic composite\
**Strategy:** Scans one string for street / PO box / city / state / ZIP
components and fires when at least three co-occur.\
**Examples:** `1225 S Walnut St, Bloomington, IN 47401`,
`30 Grandview Ct, Cheshire, CT 06410`,
`1600 Pennsylvania Ave, Washington, DC 20500`,
`350 Fifth Avenue, New York, NY 10118`,
`742 Evergreen Terrace, Springfield, IL 62704`

| Recall |    S1 |  S2 |  S3 |   SP |
|-------:|------:|----:|----:|-----:|
|      1 | 0.005 |   0 |   0 | 0.07 |

### Geography

#### `is_state_fips()`

A 2-digit state FIPS code.

**Precision:** exact lookup\
**Strategy:** Membership in the valid state/territory FIPS set.\
**Examples:** `06`, `36`, `48`, `17`, `12`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.528 | 0.528 | 0.023 |  NA |

#### `is_county_fips()`

A 5-digit county FIPS (GEOID).

**Precision:** anchor + length\
**Strategy:** Five digits whose first two are a valid state FIPS.\
**Examples:** `06037`, `36061`, `48201`, `17031`, `12086`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.742 | 0.742 | 0.016 |  NA |

#### `is_tract_fips()`

An 11-digit census-tract GEOID.

**Precision:** anchor + length\
**Strategy:** Eleven digits with a valid state prefix.\
**Examples:** `06037206200`, `36061014500`, `17031839100`,
`48201100000`, `12086001000`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.785 | 0.785 |   0 |  NA |

#### `is_block_group_fips()`

A 12-digit census block-group GEOID.

**Precision:** anchor + length\
**Strategy:** Twelve digits with a valid state prefix.\
**Examples:** `060372062001`, `360610145001`, `170318391001`,
`482011000001`, `120860010001`

| Recall |   S1 |   S2 |  S3 |  SP |
|-------:|-----:|-----:|----:|----:|
|      1 | 0.75 | 0.75 |   0 |  NA |

#### `is_block_fips()`

A 15-digit census-block GEOID.

**Precision:** anchor + length\
**Strategy:** Fifteen digits with a valid state prefix.\
**Examples:** `060372062001001`, `360610145001000`, `170318391001002`,
`482011000001003`, `120860010001000`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.731 | 0.731 |   0 |  NA |

#### `is_cbsa()`

A 5-digit Core Based Statistical Area code.

**Precision:** exact lookup\
**Strategy:** Membership in the Census CBSA code list.\
**Examples:** `10100`, `10140`, `10180`, `10220`, `10300`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.141 | 0.141 | 0.013 |  NA |

#### `is_csa()`

A 3-digit Combined Statistical Area code.

**Precision:** exact lookup\
**Strategy:** Membership in the Census CSA code list.\
**Examples:** `101`, `220`, `364`, `408`, `348`

| Recall |    S1 |    S2 |   S3 |  SP |
|-------:|------:|------:|-----:|----:|
|      1 | 0.275 | 0.275 | 0.01 |  NA |

#### `is_metro_area_name()`

A CBSA / CSA area title (metro-area name).

**Precision:** exact lookup (partial)\
**Strategy:** Normalized membership against the official metro-area
titles (full and state-stripped forms); distinct from city_name, which
will not match these hyphenated multi-city titles.\
**Examples:** `Aberdeen, SD`, `Abilene, TX`, `Akron, OH`,
`Athens-Clarke County, GA`, `Corpus Christi, TX`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

#### `is_nces_locale()`

An NCES locale code (11-13, 21-23, 31-33, 41-43).

**Precision:** small enum\
**Strategy:** Two-digit enum for City/Suburb/Town/Rural x
Large/Midsize/Small.\
**Examples:** `11`, `12`, `13`, `21`, `22`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |  NA |

#### `is_urban_rural()`

An urban / rural designation label.

**Precision:** small enum\
**Strategy:** Membership in a designation vocabulary (urban, rural,
suburban, exurban, …).\
**Examples:** `Urban`, `Rural`, `Suburban`, `Suburb`, `Exurban`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |  NA |

#### `is_census_region()`

A US census region or division name.

**Precision:** small enum\
**Strategy:** Membership in the four regions + nine divisions.\
**Examples:** `Northeast`, `Midwest`, `South`, `West`, `New England`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   0 |   0 |   0 |   0 |

### Government / entity IDs

#### `is_ssn()`

A US Social Security Number.

**Precision:** regex + rules\
**Strategy:** ddd-dd-dddd with issuance validity rules (area not
000/666/900+, group not 00, serial not 0000).\
**Examples:** `540-39-4268`, `518-07-5084`, `531-33-7396`,
`212-61-9091`, `478-46-4157`

| Recall |    S1 |   S2 |  S3 |  SP |
|-------:|------:|-----:|----:|----:|
|      1 | 0.945 | 0.21 |   0 |   0 |

#### `is_ein()`

A US Employer Identification Number.

**Precision:** structured regex\
**Strategy:** Two digits, a dash, seven digits.\
**Examples:** `15-4464349`, `58-9042990`, `17-5287634`, `11-9778467`,
`79-3293856`

| Recall |  S1 |    S2 |  S3 |  SP |
|-------:|----:|------:|----:|----:|
|      1 |   1 | 0.325 |   0 |   0 |

#### `is_dea()`

A DEA registration number.

**Precision:** checksum\
**Strategy:** Two letters + seven digits, with the DEA check digit
validated.\
**Examples:** `AP5836727`, `BJ6125341`, `AD0865937`, `AS9432042`,
`AJ3247194`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.018 | 0.018 |   0 |  NA |

#### `is_chinese_resident_id()`

A Chinese resident identity-card number.

**Precision:** checksum\
**Strategy:** Eighteen characters with an ISO 7064 mod-11-2 check
character.\
**Examples:** `141002197808194474`, `431026197506218370`,
`210811198609188735`, `371625197902109782`, `140427197602187066`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.093 | 0.093 |   0 |  NA |

#### `is_uei()`

A SAM.gov Unique Entity Identifier (the 12-character code that replaced
the DUNS number).

**Precision:** structured regex\
**Strategy:** Twelve alphanumerics excluding the letters I and O, first
character not 0.\
**Examples:** `ZQGGHJH74DW7`, `R7KZ8N2QP4M5`, `H3JD9FGT2WX6`,
`AB1CD2EF3GH4`, `M5N6P7Q8R9S2`

| Recall |  S1 |  S2 |    S3 |  SP |
|-------:|----:|----:|------:|----:|
|      1 |   1 |   1 | 0.005 |  NA |

#### `is_naics()`

A NAICS industry code (2-6 digits).

**Precision:** exact lookup\
**Strategy:** Membership in the full 2022 NAICS code set, rolled up to
every level.\
**Examples:** `11`, `236`, `311`, `541511`, `5415`

| Recall |    S1 |    S2 |    S3 |  SP |
|-------:|------:|------:|------:|----:|
|      1 | 0.137 | 0.137 | 0.004 |  NA |

### Phone

#### `is_phone()`

A US / NANP phone number.

**Precision:** loose regex\
**Strategy:** Regex over the common US formats and separators.\
**Examples:** `510-577-3201`, `(309) 647-1820`, `(609)-993-3001`,
`650-384-9911`, `1-650-384-9911`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.875 | 0.021 |   0 |   0 |

#### `is_intl_phone()`

A +-prefixed international phone number.

**Precision:** loose regex\
**Strategy:** Regex: + country code + 8-15 digits with
separators/parentheses.\
**Examples:** `+1-4250013981`, `+61 3 6216 0864`, `+64 3 477 4000`,
`+44 20 7946 0958`, `+49 30 12345678`

| Recall |  S1 |   S2 |  S3 |    SP |
|-------:|----:|-----:|----:|------:|
|      1 |   1 | 0.28 |   0 | 0.367 |

#### `is_msisdn()`

A bare MSISDN subscriber number.

**Precision:** loose regex\
**Strategy:** 10-15 digits; very loose, best paired with a variable-name
hint.\
**Examples:** `919961345678`, `13109976224`, `12481234567`,
`27821234567`, `447912345678`

| Recall |  S1 |  S2 |  S3 |  SP |
|-------:|----:|----:|----:|----:|
|      1 |   1 |   1 |   0 |  NA |

### Research / scholarly IDs

#### `is_doi()`

A Digital Object Identifier.

**Precision:** structured regex\
**Strategy:** Regex: 10./.\
**Examples:** `10.1109/ICDCSW.2017.43`, `10.1109/IRI.2016.84`,
`10.1109/ACC.2016.7526681`, `10.1109/PIMRC.2015.7343424`,
`10.1109/ICICA.2014.47`

| Recall |    S1 |    S2 |  S3 |    SP |
|-------:|------:|------:|----:|------:|
|      1 | 0.045 | 0.005 |   0 | 0.131 |

#### `is_orcid()`

An ORCID researcher iD.

**Precision:** checksum\
**Strategy:** dddd-dddd-dddd-dddC with an ISO 7064 mod-11-2 check digit
(C may be X).\
**Examples:** `0000-0002-0488-8591`, `0000-0002-6390-6569`,
`0000-0001-8666-7241`, `0000-0001-6352-7991`, `0000-0003-2738-1803`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.058 | 0.013 |   0 |   0 |

#### `is_isbn()`

An ISBN-10 or ISBN-13.

**Precision:** checksum\
**Strategy:** Validates the ISBN-10 (mod 11) or ISBN-13 (mod 10) check
digit.\
**Examples:** `140955525-9`, `038027303-9`, `489911182-7`,
`099337131-0`, `712334370-0`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.058 | 0.025 |   0 |   1 |

#### `is_issn()`

An ISSN serial number.

**Precision:** checksum\
**Strategy:** dddd-dddC with a mod-11 check digit (C may be X).\
**Examples:** `0001-2092`, `0001-253X`, `0002-0729`, `0003-021X`,
`0004-4687`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.092 | 0.033 |   0 |   0 |

#### `is_npi()`

A US National Provider Identifier.

**Precision:** checksum\
**Strategy:** Ten digits with a Luhn check over the 80840 prefix + first
nine digits.\
**Examples:** `1225155880`, `1649397217`, `1578680153`, `1346368917`,
`1487772901`

| Recall |    S1 |    S2 |  S3 |  SP |
|-------:|------:|------:|----:|----:|
|      1 | 0.085 | 0.085 |   0 |  NA |

## Adding a new detector

A detector is just a pure `is_<type>()` predicate, so adding one is
self-contained. Collect 10-25 example values of the new type and build
the same positive + hard-negative fixture the report above uses with
\[[`generate_autotype_test_cases()`](https://lecy.github.io/formex/reference/generate_autotype_test_cases.md)\]
(it generates the S1/S2/S3/SP negatives via
\[[`generate_autotype_negatives()`](https://lecy.github.io/formex/reference/generate_autotype_negatives.md)\]):

``` r

cases <- generate_autotype_test_cases(
  P         = c("ENSG00000139618", "ENSMUSG00000102659", "ENST00000407559"),
  data_type = "ensembl_id")
```

Write the
[`is_ensembl_id()`](https://lecy.github.io/formex/reference/is_ensembl_id.md)
predicate, then score it against that fixture with
\[[`build_autotype_results()`](https://lecy.github.io/formex/reference/build_autotype_results.md)\]
and
\[[`generate_autotype_report()`](https://lecy.github.io/formex/reference/generate_autotype_report.md)\]
to read the same recall/precision table shown here before you adopt it.
Once you are happy:

1.  Drop the function into an `R/dt-<family>.R` file (a character-in,
    logical-out predicate that never errors).
2.  Add its positive examples to `data-raw/datatypes/<family>.R`.
3.  Register one line in `R/00-data-type-registry.R` so
    [`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
    and
    [`score_data_type()`](https://lecy.github.io/formex/reference/score_data_type.md)
    pick it up, and add a row to the ontology
    (`inst/extdata/research_data_type_ontology_v7.csv`) for its semantic
    type.

See
[`?generate_autotype_test_cases`](https://lecy.github.io/formex/reference/generate_autotype_test_cases.md),
[`?build_autotype_results`](https://lecy.github.io/formex/reference/build_autotype_results.md),
and
[`?generate_autotype_report`](https://lecy.github.io/formex/reference/generate_autotype_report.md)
for details.
