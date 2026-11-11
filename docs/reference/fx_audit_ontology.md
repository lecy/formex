# Round-trip audit an ontology file

Runs
[`fx_roundtrip_check()`](https://lecy.github.io/formex/reference/fx_roundtrip_check.md)
across every row of an ontology CSV, using a value column (default
`examples`) as a stand-in for stable values, and returns which types
need an explicit import rule to survive a read/write round trip.

## Usage

``` r
fx_audit_ontology(path, value_col = "examples")
```

## Arguments

- path:

  Path to an ontology CSV.

- value_col:

  Column holding `;;`-separated example values.

## Value

A data frame of per-row round-trip results with the ontology path.

## See also

[`fx_roundtrip_check()`](https://lecy.github.io/formex/reference/fx_roundtrip_check.md)
