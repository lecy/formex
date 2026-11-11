# Is it a JSON object or array?

Structural check (not a full parse): the trimmed value is delimited by
[`{ }`](https://rdrr.io/r/base/Paren.html) with at least one `"key":`
member, or by `[ ]`. Catches the common "serialized structure in a cell"
case; deeply malformed JSON that still has the outer shape may pass,
which is acceptable for column-level typing.

\[ \]: R:%20

## Usage

``` r
is_json(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a JSON object or array literal.

## See also

Other serialized detectors:
[`is_tags()`](https://lecy.github.io/formex/reference/is_tags.md)

## Examples

``` r
is_json(c('{"a":1,"b":[2,3]}', "[1,2,3]", "not json", NA))
#> [1]  TRUE  TRUE FALSE    NA
```
