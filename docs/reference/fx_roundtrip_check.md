# Check whether stabilized values survive a read/write round trip

Reads a column of already-stabilized values back with both base and
type-guessing readers and reports whether the values change, the
inferred type is wrong, the readers disagree, or Excel hazards are
present – i.e. whether an explicit import rule is required to preserve
the intended storage.

## Usage

``` r
fx_roundtrip_check(stable_values, intended_storage, id = NA_character_)
```

## Arguments

- stable_values:

  Character vector of stabilized values.

- intended_storage:

  The intended storage type (e.g. `"integer"`, `"factor"`, `"date"`).

- id:

  Optional identifier carried through to the result.

## Value

A one-row data frame flagging each hazard plus `needs_import_rule`.

## See also

[`fx_audit_ontology()`](https://lecy.github.io/formex/reference/fx_audit_ontology.md)
