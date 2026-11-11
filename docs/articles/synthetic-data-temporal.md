# Synthetic Data: the Temporal Case

Every detector needs examples — positives to prove recall, near-misses
to prove precision (see
[`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md)).
For most families those examples are hand-collected. But some types can
be **synthesized**: generated in unlimited quantity, correctly labelled,
for free. The temporal family is the clearest case, and it makes a good
template for deciding when synthesis is worth it elsewhere.

## Why temporal is the ideal case

A date or time has two properties that make it cheap to synthesize:

1.  **One canonical value.** “The 15th of March, 2016” is a single point
    in time — an R `Date` or `POSIXct` — no matter how it is written.
2.  **Deterministic, enumerable rendering.** That one value can be
    written in a known, finite set of surface formats, and
    [`format()`](https://rdrr.io/r/base/format.html) renders any of them
    exactly. There is no ambiguity and no external resource required.

The temporal family is also the one with the **most surface forms**: the
shipped examples in `data-raw/datatypes/datetime.R` cover seventeen
representations of the same underlying thing —

    iso_date · iso_datetime · us_date · us_datetime · abbr_month_date · long_date
    month_year · yyyymm · month_day · clock_time · date_range · hijri_date · date
    quarter · fiscal_year · day_of_week · month_of_year

— which is exactly why hand-curating them is tedious and why generating
them pays off. The flexible date detector already carries the format
vocabulary: see `.date_formats_for()` in `R/dt-date-flex.R`, which
assembles the `strftime` patterns (`%Y-%m-%d`, `%m/%d/%y`, `%B %d, %Y`,
…) the detector tries.

## Generating positives

Sample canonical values once, then render each representation from them.
Every rendered column is correctly labelled by construction.

``` r

set.seed(514)
days <- as.Date("1970-01-01") + sample(0:20000, 200)   # 200 random dates

# one strftime pattern per representation -> one labelled synthetic column each
renderings <- list(
  iso_date        = "%Y-%m-%d",
  us_date         = "%m/%d/%Y",
  abbr_month_date = "%d-%b-%Y",
  long_date       = "%A, %B %d, %Y",
  month_year      = "%B %Y",
  yyyymm          = "%Y%m",
  day_of_week     = "%A"
)
synthetic <- lapply(renderings, function(fmt) format(days, fmt))

str(synthetic$iso_date)   #> "1997-05-19" "2031-11-02" ...
str(synthetic$long_date)  #> "Monday, May 19, 1997" ...
```

Because the label is the key of `renderings`, a few lines produce
hundreds of columns across every temporal representation — the positives
a detector or the router needs, with no hand-labelling.

## Generating hard negatives for free

Synthesis also hands you negatives that hand-curation cannot easily
produce:

- **Out-of-range but well-formed:** render month 13 or day 32 to test
  that a detector enforces ranges, not just the shape (`"2016-13-05"`).
- **Format collisions:** `%m/%d/%Y` vs `%d/%m/%Y` (“03/04/2016”) are the
  same string for different dates — a built-in ambiguity case.
- **The AutoType tiers on top:** feed the synthetic positives to
  [`generate_autotype_negatives()`](https://lecy.github.io/formex/reference/generate_autotype_negatives.md)
  for the structure-scramble (`SP`) near-misses that catch a mask
  checking characters but not placement.

This pairs directly with the mask-refinement loop in
[`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md):
synthesize the positives, scramble them into negatives, score, tighten.

## The round-trip connection

Rendering a canonical value *out* to a surface string is exactly what
the formex format syntax does *in reverse*: each temporal ontology row
carries a recipe for reading a raw value back to its stable ISO form
(see
[`vignette("formex")`](https://lecy.github.io/formex/articles/formex.md)).
A synthetic generator and a `formex` import recipe are two directions of
the same format vocabulary, which is why a representation you can
generate is also one you can stabilize.

## When synthesis generalizes — and when it doesn’t

The temporal recipe — *sample a canonical value, render
deterministically* — works for any family built the same way:

| Synthesizable | Why |
|----|----|
| temporal | canonical instant + `strftime` rendering |
| coordinates | canonical lat/lon + DMS / decimal / ISO-6709 rendering |
| checksummed identifiers (ISBN, ORCID, NPI) | generate the body, compute the check digit |
| currency amounts | sample a number + symbol/grouping/decimals rendering |

It breaks down where values are defined by **membership** rather than by
a rendering rule:

- **Names, cities, states** — there is no formula for “a surname”; you
  need a gazetteer (see
  [`vignette("feature-engineering")`](https://lecy.github.io/formex/articles/feature-engineering.md)
  on the lexicon features).
- **Free text (titles, descriptions)** — no canonical value to render.

The test for whether to synthesize a family: *can you write the value’s
canonical form and a function that renders it?* If yes, generate; if no,
collect.

## See also

- [`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md)
  — turning positives into hard negatives.
- [`vignette("adding-a-detector")`](https://lecy.github.io/formex/articles/adding-a-detector.md)
  — where generated examples fit in adding a type.
- [`vignette("formex")`](https://lecy.github.io/formex/articles/formex.md)
  — the recipe syntax that reads these renderings back in.
