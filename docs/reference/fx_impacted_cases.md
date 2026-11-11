# Map an ontology diff onto banked cases

Matches diff rows to schema-v2 case files on `label.semantic_type_id`
(never on text), applies the depth rule (a case is affected only by
changes at or above the depth it was labelled to) and the version rule
(already-migrated cases are skipped), and optionally flags affected
cases by writing ONLY `label.needs_relabel` / `label.relabel_trigger`.

## Usage

``` r
fx_impacted_cases(diff, bank_dir, new_version = NULL, write = FALSE)
```

## Arguments

- diff:

  Output of
  [`fx_ontology_diff()`](https://lecy.github.io/formex/reference/fx_ontology_diff.md).

- bank_dir:

  Directory of schema-v2 case JSON files.

- new_version:

  If set, cases already at this `label.ontology_version` are skipped.

- write:

  If `TRUE`, write the two label flags into affected files.

## Value

A data frame: `case_id`, `file`, `semantic_type_id`, `change_kind`,
`case_impact`, `action`, `relabel_trigger`.
