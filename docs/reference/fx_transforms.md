# The transform registry (v7, experimental)

The list of edges
[`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md)
searches. Each edge is a `read_`/`write_`/`convert_` step with a `from`
node, a `to` node, and the function that performs it.

## Usage

``` r
fx_transforms()
```

## Value

A list of transform edges.

## See also

[`fx_plan_transform()`](https://lecy.github.io/formex/reference/fx_plan_transform.md)
