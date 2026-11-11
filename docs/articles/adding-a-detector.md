# Adding a Detector

A detector is the smallest unit of extension in `formex`: a pure
`is_<type>()` predicate that answers one yes/no question about each
value. Adding a type means writing that predicate, proving it with a
fixture, and wiring it into the registry and ontology so
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
can route to it. This guide walks the whole path with a worked example.
It builds on
[`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md)
(what structure to key on) and
[`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md)
(how to prove it).

## What a detector is

A predicate: character in, logical out, the same length, and it **never
errors** on messy input.

``` r

is_ensembl_id <- function(x) {
  x <- as.character(x)
  grepl("^ENS[A-Z]*[GTP][0-9]{11}$", x)   # ENSG/ENST/ENSP + 11 digits
}
is_ensembl_id(c("ENSG00000139618", "ENST00000407559", "not-an-id", NA))
#> TRUE TRUE FALSE NA
```

Missing values pass through as `NA`; nothing throws. That is the entire
contract.

## The six steps

### 1. Collect 10-25 positives

Real values, varied enough to cover the format’s range (different
prefixes, lengths, edge cases).

``` r

P <- c("ENSG00000139618", "ENSMUSG00000102659", "ENST00000407559",
       "ENSP00000354587", "ENSG00000157764")
```

### 2. Build a fixture of positives + hard negatives

[`generate_autotype_test_cases()`](https://lecy.github.io/formex/reference/generate_autotype_test_cases.md)
mutates the positives into S1/S2/S3/SP near-misses (see
[`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md)
for the tiers).

``` r

cases <- generate_autotype_test_cases(P, data_type = "ensembl_id")
table(cases$label)   #> valid + S1/S2/S3/SP negatives
```

### 3. Pick a strategy and write the predicate

Choose the tightest structure the type supports
([`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md)
lists them: lookup, structured regex, regex+range, anchor+length,
checksum). Ensembl IDs are a **structured regex**: a fixed prefix and an
11-digit body.

### 4. Score it and iterate

Run the detector against the fixture and read the recall / per-tier
false-positive table. Tighten until **recall is 1.00** and the
structure-scramble tier **SP is near 0**.

``` r

res <- build_autotype_results(is_ensembl_id, P)
autotype_summary(res)              # recall + S1/S2/S3/SP pass rates
generate_autotype_report(res, "ensembl_id")   # the exact near-misses still passing
```

### 5. Wire it into the package

Four files, each touched once:

| File | Add |
|----|----|
| `R/dt-<family>.R` | the `is_<type>()` function (here `R/dt-scibio.R`) |
| `data-raw/datatypes/<family>.R` | the positive-example vector, named exactly `<type>` |
| `R/00-data-type-registry.R` | one registry line: `detector` + human `label` |
| `inst/extdata/research_data_type_ontology_v7.csv` | a row for the semantic type (its `data_type`/`semantic_family`/`semantic_type` and its formex recipe) |

The registry line is what
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)
and
[`score_data_type()`](https://lecy.github.io/formex/reference/score_data_type.md)
read; the ontology row is what lets the guess resolve to a semantic path
and carry a stabilization recipe (see
[`vignette("data-type-ontology")`](https://lecy.github.io/formex/articles/data-type-ontology.md)
and
[`vignette("formex")`](https://lecy.github.io/formex/articles/formex.md)).

``` r

# R/00-data-type-registry.R
ensembl_id = list(detector = "is_ensembl_id",
                  label    = "Ensembl gene/transcript ID")
```

The example-vector name must match the registry key (`ensembl_id`), so
the build script can pair positives with the detector automatically.

### 6. Rebuild the test bank and validate

Regenerate the frozen fixtures and check the ontology is still
consistent.

``` r

# from the package root:
#   Rscript data-raw/build_test_cases.R        # refresh data_type_tests
#   fx_validate_ontology(fx_ontology())        # ontology integrity
guess_data_type(P)$route   # the new type should now resolve
```

## A note on loose formats

Not every type can reach recall 1.00 / SP 0. A loose format (a bare
integer code, a free-text-ish token) will leak negatives no matter how
the regex is written — that is a true statement about the data, not a
bug.
[`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md)
calls these out, and the honest move is to register the type at the
depth its values actually support, letting the router’s name evidence
and the verifier’s foil-selectivity gate do the rest, rather than
forcing a brittle rule.

## See also

- [`vignette("detector-kinds")`](https://lecy.github.io/formex/articles/detector-kinds.md)
  — the structure a detector can key on.
- [`vignette("autotype-framework")`](https://lecy.github.io/formex/articles/autotype-framework.md)
  — the fixture and mask-refinement loop.
- [`vignette("data-type-ontology")`](https://lecy.github.io/formex/articles/data-type-ontology.md)
  /
  [`vignette("formex")`](https://lecy.github.io/formex/articles/formex.md)
  — wiring the semantic type and its stabilization recipe.
