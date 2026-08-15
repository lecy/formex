# Type signature + distances (§6). path_distance is a priori (taxonomy);
# signature_distance is empirical (data). Format is NOT a path level, so two
# formats of one semantic_type must have path_distance 0.

test_that("signature_distance is a proper (bounded, symmetric) semi-metric", {
  sa <- fx_type_signature(c("2020-01-01","2020-02-02","2020-03-03"))
  sb <- fx_type_signature(c("123-45-6789","987-65-4321","111-22-3333"))
  expect_equal(fx_signature_distance(sa, sa), 0, tolerance = 1e-9)
  expect_equal(fx_signature_distance(sa, sb), fx_signature_distance(sb, sa),
               tolerance = 1e-9)
  d <- fx_signature_distance(sa, sb); expect_gte(d, 0); expect_lte(d, 1)
})

test_that("path_distance returns exactly 0, 1/3, 2/3, 1", {
  base <- "number/quantity/measurement"
  expect_equal(fx_path_distance(base, base), 0)
  expect_equal(fx_path_distance(base, "number/quantity/count"), 1/3)
  expect_equal(fx_path_distance(base, "number/portion/percent"), 2/3)
  expect_equal(fx_path_distance(base, "text/name/person"), 1)
})

test_that("format variants of one semantic_type have path_distance 0", {
  # variants live below semantic_type, so the 3-level path is identical
  expect_equal(fx_path_distance("temporal/date/calendar",
                                "temporal/date/calendar"), 0)
})

test_that("exported tunable weights are present and named per axis", {
  expect_true(is.numeric(SIGNATURE_WEIGHTS))
  expect_setequal(names(SIGNATURE_WEIGHTS),
                  c("composition","numeric_gap","rigidity","width",
                    "punctuation","tokenization","cardinality"))
  expect_true(is.numeric(WEIGHTS_FORMAT))
})
