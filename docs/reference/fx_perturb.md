# Perturb a column along one stress dimension

Perturb a column along one stress dimension

## Usage

``` r
fx_perturb(values, dimension, level, foil = NULL, seed = NULL)
```

## Arguments

- values:

  Character vector (a reconstructed column).

- dimension:

  One of the names in
  [`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)'s
  default set.

- level:

  The graded level for that dimension (e.g. `"low"`, `"medium"`, or
  `"n50"`/`"n100"`/`"n300"` for `length`).

- foil:

  For `contamination`, a character vector of values drawn from a
  different data type to mix in.

- seed:

  Optional integer seed for reproducibility.

## Value

A perturbed character vector.

## See also

[`fx_stress_grid()`](https://lecy.github.io/formex/reference/fx_stress_grid.md)
