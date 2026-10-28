# fx_stabilize() executes an ontology recipe (raw_to_stable_transform DSL) and
# returns the recipe outputs plus the v7 render fields. Verbs reuse the package
# detectors/lexicons.

test_that("fx_stabilize returns the recipe fields plus the v7 render fields", {
  r <- fx_stabilize(c("03/15/2019", "12/31/2020"), "calendar")
  expect_named(r, c("variant_id", "format_mask", "stable", "stable_format",
                    "import_rule", "rendered", "target_format", "target_reachable",
                    "conversion_log"))
  expect_equal(r$stable, c("2019-03-15", "2020-12-31"))   # dates canonicalize to ISO
  expect_equal(r$rendered, r$stable)                      # no target -> rendered == stable
  expect_true(is.na(r$target_reachable))                  # NA when no target requested
  expect_equal(r$conversion_log$dropped, 0)               # nothing lost here
})

test_that("the conversion log counts dropped values and fx_stabilize warns", {
  expect_warning(
    r <- fx_stabilize(c("$2,300.00", "17,298$", "-45"), "usd"),  # bare -45 has no symbol
    "could not be stabilized")
  expect_equal(r$conversion_log$dropped, 1)
  expect_equal(r$conversion_log$stabilized, 2)
  expect_equal(r$conversion_log$examples, "-45")
  # warn = FALSE silences the warning but still logs the drop
  expect_silent(r2 <- fx_stabilize(c("$2,300.00", "-45"), "usd", warn = FALSE))
  expect_equal(r2$conversion_log$dropped, 1)
})

test_that("target_format renders the canonical values via the planner", {
  r <- fx_stabilize("03/15/2019", "calendar", target_format = "mdy_slash")
  expect_true(r$target_reachable)
  expect_equal(r$stable, "2019-03-15")       # canonical is unchanged
  expect_equal(r$rendered, "03/15/2019")     # rendered to the requested style
})

test_that("stabilizing to the canonical default format is reachable (identity)", {
  # a date (written or ISO) renders to its yyyymmdd default -- the baseball
  # birthDate / debut case that used to be "not transformable"
  r <- fx_stabilize(c("Dec 27, 1981", "1975-01-05"), "calendar", target_format = "yyyymmdd")
  expect_true(r$target_reachable)
  expect_equal(r$rendered, c("1981-12-27", "1975-01-05"))
  expect_true(fx_transformable(fx_format("measurement"), fx_format("measurement", "numeric")))
  expect_true(fx_transformable(fx_format("year"), fx_format("year", "yyyy")))
})

test_that("an unreachable target_format falls back to canonical", {
  r <- fx_stabilize("03/15/2019", "calendar", target_format = "no_such_style")
  expect_false(r$target_reachable)
  expect_equal(r$rendered, r$stable)
})

test_that("recipe granularity: ISBN normalizes then validates", {
  # strip the 'isbn ' prefix and hyphens, then validate the checksum
  expect_equal(fx_stabilize(c("isbn 0395629764"), "administrative", "isbn")$stable, "0395629764")
})

test_that("lookup MAPS to canonical (name or code -> canonical)", {
  expect_equal(fx_stabilize(c("California", "TX", "Ohio"), "geographic", "us_state")$stable,
               c("CA", "TX", "OH"))
  expect_equal(fx_stabilize(c("France", "de", "Japan"), "geographic", "iso_country")$stable,
               c("FR", "DE", "JP"))
})

test_that("fx_transform runs a DSL expression directly", {
  expect_equal(fx_transform("$1,234.50", "{{ as_usd }}"), "1234.5")
  expect_equal(fx_transform(c("2004", "banana"), "{{ as_yyyy }}"), c("2004", NA))
  # an unimplemented verb yields all-NA with an attribute, not an error
  expect_true(all(is.na(fx_transform("x", "{{ no_such_verb }}"))))
})

test_that("unknown semantic_type errors; bad format_label errors", {
  expect_error(fx_stabilize("x", "not_a_real_type"))
  expect_error(fx_stabilize("x", "administrative", "not_a_variant"))
})
