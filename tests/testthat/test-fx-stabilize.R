# fx_stabilize() executes an ontology recipe (raw_to_stable_transform DSL) and
# returns the recipe's four outputs. Verbs reuse the package detectors/lexicons.

test_that("fx_stabilize returns the recipe's four fields", {
  r <- fx_stabilize(c("03/15/2019", "12/31/2020"), "calendar")
  expect_named(r, c("variant_id", "format_mask", "stable", "stable_format", "import_rule"))
  expect_equal(r$stable, c("2019-03-15", "2020-12-31"))   # dates canonicalize to ISO
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
