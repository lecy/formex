# Is it a Month-Day value (no year)?

Is it a Month-Day value (no year)?

## Usage

``` r
is_month_day(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `Month D` (e.g. `February 6`).

## See also

Other datetime detectors:
[`is_abbr_month_date()`](https://lecy.github.io/formex/reference/is_abbr_month_date.md),
[`is_clock_time()`](https://lecy.github.io/formex/reference/is_clock_time.md),
[`is_date()`](https://lecy.github.io/formex/reference/is_date.md),
[`is_date_range()`](https://lecy.github.io/formex/reference/is_date_range.md),
[`is_day_of_week()`](https://lecy.github.io/formex/reference/is_day_of_week.md),
[`is_fiscal_year()`](https://lecy.github.io/formex/reference/is_fiscal_year.md),
[`is_hijri_date()`](https://lecy.github.io/formex/reference/is_hijri_date.md),
[`is_iso_date()`](https://lecy.github.io/formex/reference/is_iso_date.md),
[`is_iso_datetime()`](https://lecy.github.io/formex/reference/is_iso_datetime.md),
[`is_long_date()`](https://lecy.github.io/formex/reference/is_long_date.md),
[`is_month_of_year()`](https://lecy.github.io/formex/reference/is_month_of_year.md),
[`is_month_year()`](https://lecy.github.io/formex/reference/is_month_year.md),
[`is_quarter()`](https://lecy.github.io/formex/reference/is_quarter.md),
[`is_rfc2822_datetime()`](https://lecy.github.io/formex/reference/is_rfc2822_datetime.md),
[`is_us_date()`](https://lecy.github.io/formex/reference/is_us_date.md),
[`is_us_datetime()`](https://lecy.github.io/formex/reference/is_us_datetime.md),
[`is_yyyymm()`](https://lecy.github.io/formex/reference/is_yyyymm.md)

## Examples

``` r
is_month_day(c("February 6", "February 1987", NA))
#> [1]  TRUE FALSE    NA
```
