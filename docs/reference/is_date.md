# Is it a date or timestamp?

A tolerant detector: recognizes a calendar date or datetime in
essentially any plausible written form (ISO, US, European, named-month,
with or without time, 12/24-hour, `T`-separated, offsets, fractional
seconds, weekday prefixes) by trying a library of `strptime` formats.
Non-dates – counts, ZIPs, phones, ids, free text – are rejected by the
in-range + round-trip guard.

## Usage

``` r
is_date(x, min_year = 1900, max_year = 2100)
```

## Arguments

- x:

  A character vector.

- min_year, max_year:

  Plausible calendar-year window (default 1900-2100).

## Value

Logical vector; `TRUE` for a parseable in-range date/timestamp.

## See also

Other datetime detectors:
[`is_abbr_month_date()`](https://lecy.github.io/formex/reference/is_abbr_month_date.md),
[`is_clock_time()`](https://lecy.github.io/formex/reference/is_clock_time.md),
[`is_date_range()`](https://lecy.github.io/formex/reference/is_date_range.md),
[`is_day_of_week()`](https://lecy.github.io/formex/reference/is_day_of_week.md),
[`is_fiscal_year()`](https://lecy.github.io/formex/reference/is_fiscal_year.md),
[`is_hijri_date()`](https://lecy.github.io/formex/reference/is_hijri_date.md),
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
is_date(c("2016-03-15", "05/Mar/2016", "March 5, 2016 2:00 PM",
          "20160305T14:00:00Z", "banana", "12345"))
#> [1]  TRUE  TRUE  TRUE  TRUE FALSE FALSE
```
