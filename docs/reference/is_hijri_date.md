# Is it a Hijri (Islamic-calendar) date?

Is it a Hijri (Islamic-calendar) date?

## Usage

``` r
is_hijri_date(x)
```

## Arguments

- x:

  A character vector.

## Value

Logical vector; `TRUE` for `D <Islamic month> YYYY`.

## See also

Other datetime detectors:
[`is_abbr_month_date()`](https://lecy.github.io/formex/reference/is_abbr_month_date.md),
[`is_clock_time()`](https://lecy.github.io/formex/reference/is_clock_time.md),
[`is_date()`](https://lecy.github.io/formex/reference/is_date.md),
[`is_date_range()`](https://lecy.github.io/formex/reference/is_date_range.md),
[`is_day_of_week()`](https://lecy.github.io/formex/reference/is_day_of_week.md),
[`is_fiscal_year()`](https://lecy.github.io/formex/reference/is_fiscal_year.md),
[`is_iso_date()`](https://lecy.github.io/formex/reference/is_iso_date.md),
[`is_iso_datetime()`](https://lecy.github.io/formex/reference/is_iso_datetime.md),
[`is_long_date()`](https://lecy.github.io/formex/reference/is_long_date.md),
[`is_month_day()`](https://lecy.github.io/formex/reference/is_month_day.md),
[`is_month_of_year()`](https://lecy.github.io/formex/reference/is_month_of_year.md),
[`is_month_year()`](https://lecy.github.io/formex/reference/is_month_year.md),
[`is_quarter()`](https://lecy.github.io/formex/reference/is_quarter.md),
[`is_rfc2822_datetime()`](https://lecy.github.io/formex/reference/is_rfc2822_datetime.md),
[`is_us_date()`](https://lecy.github.io/formex/reference/is_us_date.md),
[`is_us_datetime()`](https://lecy.github.io/formex/reference/is_us_datetime.md),
[`is_yyyymm()`](https://lecy.github.io/formex/reference/is_yyyymm.md)

## Examples

``` r
is_hijri_date(c("11 Shawwal 1430", "5 Muharram 1300", NA))
#> [1] TRUE TRUE   NA
```
