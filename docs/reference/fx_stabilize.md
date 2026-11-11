# Stabilize a column via its ontology recipe

Resolves the recipe row for a `semantic_type` (and optional
`format_label`) and runs its `raw_to_stable_transform`, returning the
recipe's four outputs.

## Usage

``` r
fx_stabilize(
  x,
  semantic_type,
  format_label = NULL,
  target_format = NULL,
  ontology = fx_ontology(),
  warn = TRUE
)
```

## Arguments

- x:

  A character vector (one column of raw values).

- semantic_type:

  The ontology leaf, e.g. `"calendar"`, `"administrative"`.

- format_label:

  Optional variant within the type, e.g. `"isbn"`. If `NULL` the first
  variant of the semantic_type is used.

- target_format:

  Optional `format_style` to render the stabilized values into (v7). The
  canonical `stable` values are passed through the transform planner
  ([`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md))
  to the requested written form; when no `write_*`/`convert_*` path
  exists yet, `rendered` falls back to `stable` and `target_reachable`
  is `FALSE`.

- ontology:

  An ontology data frame (defaults to
  [`fx_ontology()`](https://lecy.github.io/formex/reference/fx_ontology.md)).

- warn:

  If `TRUE` (default), emit a warning when present values could not be
  stabilized (became `NA`), reporting the count and a few examples, so
  silent data loss is surfaced rather than hidden.

## Value

A list: `variant_id`, `format_mask` (recognition pattern, from
`data_format`), `stable` (the canonical transformed values),
`stable_format` (canonical target), `import_rule` (how to re-ingest),
the v7 render fields `rendered` (values in `target_format`, or `stable`
if none/unreached), `target_format`, and `target_reachable`
(`TRUE`/`FALSE`, or `NA` when no `target_format` was requested), and a
**`conversion_log`**: a list of `n` (present values), `stabilized`,
`dropped`, `drop_rate`, `reason`, and up to five dropped `examples` —
the audit of which values the recipe could not convert and why.

## See also

[`fx_transform()`](https://lecy.github.io/formex/reference/fx_transform.md),
[`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md),
[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

## Examples

``` r
fx_stabilize(c("03/15/2019", "12/31/2020"), "calendar")
#> $variant_id
#> [1] "n0059-f01"
#> 
#> $format_mask
#> [1] "{{ mmddyyyy }}"
#> 
#> $stable
#> [1] "2019-03-15" "2020-12-31"
#> 
#> $stable_format
#> [1] "2019-03-15 ;; 2019-03-15"
#> 
#> $import_rule
#> [1] "{{ as_yyyymmdd }}"
#> 
#> $rendered
#> [1] "2019-03-15" "2020-12-31"
#> 
#> $target_format
#> [1] NA
#> 
#> $target_reachable
#> [1] NA
#> 
#> $conversion_log
#> $conversion_log$n
#> [1] 2
#> 
#> $conversion_log$stabilized
#> [1] 2
#> 
#> $conversion_log$dropped
#> [1] 0
#> 
#> $conversion_log$drop_rate
#> [1] 0
#> 
#> $conversion_log$reason
#> [1] NA
#> 
#> $conversion_log$examples
#> character(0)
#> 
#> 
fx_stabilize(c("03/15/2019"), "calendar", target_format = "mdy_slash")
#> $variant_id
#> [1] "n0059-f01"
#> 
#> $format_mask
#> [1] "{{ mmddyyyy }}"
#> 
#> $stable
#> [1] "2019-03-15"
#> 
#> $stable_format
#> [1] "2019-03-15 ;; 2019-03-15"
#> 
#> $import_rule
#> [1] "{{ as_yyyymmdd }}"
#> 
#> $rendered
#> [1] "03/15/2019"
#> 
#> $target_format
#> [1] "mdy_slash"
#> 
#> $target_reachable
#> [1] TRUE
#> 
#> $conversion_log
#> $conversion_log$n
#> [1] 1
#> 
#> $conversion_log$stabilized
#> [1] 1
#> 
#> $conversion_log$dropped
#> [1] 0
#> 
#> $conversion_log$drop_rate
#> [1] 0
#> 
#> $conversion_log$reason
#> [1] NA
#> 
#> $conversion_log$examples
#> character(0)
#> 
#> 
fx_stabilize(c("isbn 0395629764"), "administrative", "isbn")
#> $variant_id
#> [1] "n0073-f02"
#> 
#> $format_mask
#> [1] "{{ id:isbn }}"
#> 
#> $stable
#> [1] "0395629764"
#> 
#> $stable_format
#> [1] "9780140448061"
#> 
#> $import_rule
#> [1] "{{ as_id }}"
#> 
#> $rendered
#> [1] "0395629764"
#> 
#> $target_format
#> [1] NA
#> 
#> $target_reachable
#> [1] NA
#> 
#> $conversion_log
#> $conversion_log$n
#> [1] 1
#> 
#> $conversion_log$stabilized
#> [1] 1
#> 
#> $conversion_log$dropped
#> [1] 0
#> 
#> $conversion_log$drop_rate
#> [1] 0
#> 
#> $conversion_log$reason
#> [1] NA
#> 
#> $conversion_log$examples
#> character(0)
#> 
#> 
```
