# Plan a transform from one format to another (v7, experimental)

Breadth-first search over the transform
[`fx_transforms()`](https://lecy.github.io/formex/reference/fx_transforms.md)
registry for the shortest composition of `read_`/`convert_`/`write_`
steps that takes a value from the input format to the desired one.
Returns the path, or a result marked not transformable when no such path
exists ("if you can get there from here").

## Usage

``` r
fx_plan_transform(from, to, registry = NULL)
```

## Arguments

- from, to:

  [`fx_format()`](https://lecy.github.io/formex/reference/fx_format.md)
  descriptors.

- registry:

  A transform-edge list; defaults to
  [`fx_transforms()`](https://lecy.github.io/formex/reference/fx_transforms.md).

## Value

An `fx_plan`: a list with `transformable` (logical), `path` (the ordered
edges), `from`, `to`, and `reason` (when not transformable).

## See also

[`fx_transformable()`](https://lecy.github.io/formex/reference/fx_transformable.md),
[`fx_apply_plan()`](https://lecy.github.io/formex/reference/fx_apply_plan.md)

## Examples

``` r
fx_plan_transform(fx_format("temperature", "celsius", "C"),
                  fx_format("temperature", "fahrenheit", "F"))
#> <fx_plan: read_celsius :: convert_C_F :: write_fahrenheit>
```
