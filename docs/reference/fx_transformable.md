# Is one format reachable from another? (v7, experimental)

Is one format reachable from another? (v7, experimental)

## Usage

``` r
fx_transformable(from, to, registry = NULL)
```

## Arguments

- from, to:

  [`fx_format()`](https://lecy.github.io/formex/reference/fx_format.md)
  descriptors.

- registry:

  A transform-edge list; defaults to
  [`fx_transforms()`](https://lecy.github.io/formex/reference/fx_transforms.md).

## Value

`TRUE` if a transform path exists, else `FALSE`.

## See also

[`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md)
