# Run an ontology transform-DSL expression on a vector

Low-level executor behind
[`fx_stabilize()`](https://lecy.github.io/formex/reference/fx_stabilize.md).
Parses the recipe grammar (`{{ verb }}`, `verb:arg`, `[step][step]`,
`verb+verb`) and applies each verb.

## Usage

``` r
fx_transform(x, expr)
```

## Arguments

- x:

  A character vector of raw values.

- expr:

  A transform expression from `raw_to_stable_transform`.

## Value

A character vector of stabilized values; `NA` where the recipe cannot
apply. An unimplemented verb yields all-`NA` with an `unimplemented`
attribute.

## See also

[`fx_stabilize()`](https://lecy.github.io/formex/reference/fx_stabilize.md)
