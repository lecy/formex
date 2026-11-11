# Apply the mechanical half of a bank migration

`merged`/`renamed`/`moved` cases are rewritten automatically (id/path in
the label, plus `ontology_version` and a `notes` append);
`split`/`deprecated` cases are flagged `needs_relabel` and left for a
human. Dry-run by default.

## Usage

``` r
fx_migrate_bank(diff, bank_dir, new_version, write = FALSE)
```

## Arguments

- diff:

  Output of
  [`fx_ontology_diff()`](https://lecy.github.io/formex/reference/fx_ontology_diff.md).

- bank_dir:

  Directory of schema-v2 case files.

- new_version:

  The version string to stamp on migrated cases.

- write:

  If `TRUE`, modify files (label block only).

## Value

A one-row summary: `n_migrated`, `n_flagged`, `n_orphaned`, `n_skipped`.
