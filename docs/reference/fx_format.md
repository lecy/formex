# A value's format descriptor (v7, experimental)

The three coordinates a transform search ranges over: the
`semantic_type` (what the value is), the `format_style` (how it is
written – field order, separators, suffixes), and the `unit_type` (the
dimensional/categorical unit that carries meaning, e.g. `"C"`/`"F"`,
`"USD"`, `"fiscal"`).

## Usage

``` r
fx_format(
  semantic_type,
  format_style = NA_character_,
  unit_type = NA_character_
)
```

## Arguments

- semantic_type:

  The ontology semantic type (e.g. `"calendar"`).

- format_style:

  The written rendering, or `NA`.

- unit_type:

  The dimensional/categorical unit, or `NA`.

## Value

An object of class `fx_format`.

## See also

[`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md)
