# Is it a tag set (a delimited multi-value field)?

Tests whether each value is a flat set of short members joined by `;` or
`|` — the shape a multi-select / "tags" column takes once a list is
collapsed to a string (`"Volunteer;Donor;Board"`, `"a|b|c"`). Requires a
`;`/`|` delimiter and at least two non-empty, reasonably short members,
so ordinary prose or single values do not match. (Comma is intentionally
excluded — it is too common in numbers, names and sentences to be a
reliable set delimiter.)

## Usage

``` r
is_tags(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for a delimited set of 2+ members, `FALSE`
otherwise, `NA` where `x` is `NA`.

## See also

[`guess_data_type()`](https://lecy.github.io/formex/reference/guess_data_type.md)

Other serialized detectors:
[`is_json()`](https://lecy.github.io/formex/reference/is_json.md)

## Examples

``` r
is_tags(c("Volunteer;Donor;Board", "a|b|c", "hello", "a;", NA))
#> [1]  TRUE  TRUE FALSE FALSE    NA
#> TRUE TRUE FALSE FALSE NA
```
