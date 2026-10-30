# Geographic coordinate detectors (number/coordinate family, sec 6.3). The
# value-typable PAIR forms only -- DMS with N/S/E/W letters, a decimal-degree
# pair, and ISO 6709. Bare single lat/lon columns are metadata-gated and have no
# detector by design. The degree symbol is built from a code point so the test
# source stays ASCII (matching R/dt-coordinate.R).

deg <- intToUtf8(0x00b0L)
dms <- function(d, m, s, h) sprintf("%d%s %02d' %02d\" %s", d, deg, m, s, h)

test_that("is_coord_latlon matches lat-first DMS and decimal pairs", {
  expect_true(all(is_coord_latlon(c(
    paste0(dms(40, 44, 55, "N"), ", ", dms(74, 0, 22, "W")),   # DMS, lat first
    "34.0522, -118.2437",                                      # decimal, lat first
    "-33.868800, 151.209300"))))
  # a lon-first DMS pair is NOT lat_lon; a bracketed interval / bare number isn't either
  expect_false(is_coord_latlon(paste0(dms(74, 0, 22, "W"), ", ", dms(40, 44, 55, "N"))))
  expect_false(is_coord_latlon("[-0.05, 1.20]"))
  expect_false(is_coord_latlon("34.0522"))
  # out of range (lat > 90) is rejected
  expect_false(is_coord_latlon("95.0000, 10.0000"))
  expect_true(is.na(is_coord_latlon(NA)))
})

test_that("is_coord_lonlat matches lon-first pairs only", {
  expect_true(is_coord_lonlat(paste0(dms(74, 0, 22, "W"), ", ", dms(40, 44, 55, "N"))))
  expect_true(is_coord_lonlat("-118.2437, 34.0522"))          # decimal, |first| > 90 -> lon first
  expect_false(is_coord_lonlat(paste0(dms(40, 44, 55, "N"), ", ", dms(74, 0, 22, "W"))))
  expect_false(is_coord_lonlat("34.0522, 40.1000"))           # ambiguous small pair -> lat_lon, not lon_lat
  expect_true(is.na(is_coord_lonlat(NA)))
})

test_that("is_iso6709 matches the compact signed-decimal pair", {
  expect_true(all(is_iso6709(c("+40.7128-074.0060", "-33.8688+151.2093/"))))
  expect_false(is_iso6709("40.7128, -74.0060"))               # needs the sign-delimited form
  expect_false(is_iso6709("+95.0-10.0"))                      # lat out of range
  expect_true(is.na(is_iso6709(NA)))
})

test_that("coordinate verbs canonicalize to lat-first decimal degrees, NA otherwise", {
  expect_equal(fx_transform(paste0(dms(34, 3, 0, "N"), ", ", dms(118, 15, 0, "W")),
                            "{{ as_coord_latlon }}"),
               "34.050000, -118.250000")
  # lon_lat reorders to lat first
  expect_equal(fx_transform(paste0(dms(118, 15, 0, "W"), ", ", dms(34, 3, 0, "N")),
                            "{{ as_coord_lonlat }}"),
               "34.050000, -118.250000")
  expect_equal(fx_transform("+40.7128-074.0060", "{{ as_coord_latlon_iso }}"),
               "40.712800, -74.006000")
  expect_true(is.na(fx_transform("10 to 40", "{{ as_coord_latlon }}")))  # a range is not a coordinate
})

test_that("guess_data_type routes coordinate columns to the right leaf", {
  latlon <- vapply(1:8, function(i)
    paste0(dms(sample(0:89, 1), sample(0:59, 1), sample(0:59, 1), "N"), ", ",
           dms(sample(0:179, 1), sample(0:59, 1), sample(0:59, 1), "W")), character(1))
  expect_equal(guess_data_type(latlon)$route$semantic_type, "lat_lon")

  lonlat <- vapply(1:8, function(i)
    paste0(dms(sample(0:179, 1), sample(0:59, 1), sample(0:59, 1), "W"), ", ",
           dms(sample(0:89, 1), sample(0:59, 1), sample(0:59, 1), "N")), character(1))
  expect_equal(guess_data_type(lonlat)$route$semantic_type, "lon_lat")

  # a western-hemisphere decimal column (lat > lon numerically) routes to coordinate,
  # not min_max -- the descending comma pair is not a valid ascending range
  dec <- c("34.146814,-118.137688", "33.579241,-117.726202", "33.641743,-117.838859",
           "33.752092,-117.991859", "33.758492,-118.363018", "33.761131,-118.128905")
  expect_equal(guess_data_type(dec)$route$semantic_family, "coordinate")
})

test_that("an ascending comma range still resolves to min_max, not a coordinate", {
  # guards the as_range tightening: ascending comma/`to` pairs stay ranges
  r <- guess_data_type(c("1.2, 3.4", "5 to 9", "3.4, 7.8", "10 to 20"))
  expect_equal(r$route$semantic_type, "min_max")
})
