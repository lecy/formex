# DGF field seam (INTEGRATION §5.1). depth_labeled is a prefix length: a shallow
# prediction is valid, not a failure.

test_that("full path -> depth 3, all fields present", {
  f <- fx_dgf_fields("number","quantity","measurement", "n0001",
                     confidence=0.9, detector_id="det.mask.v1")
  expect_equal(f$depth_labeled, 3L)
  expect_equal(f$data_type, "number")
  expect_equal(f$confidence, 0.9)
  expect_equal(f$detector_id, "det.mask.v1")
})

test_that("shallow prediction (data_type only) is a valid depth-1 answer", {
  f <- fx_dgf_fields("number")
  expect_equal(f$depth_labeled, 1L)
  expect_true(is.na(f$semantic_family))
})

test_that("no prediction -> depth 0", {
  expect_equal(fx_dgf_fields()$depth_labeled, 0L)
})

test_that("a bare semantic_type_id resolves its path from the ontology", {
  f <- fx_dgf_fields(semantic_type_id = "n0001")   # number/quantity/measurement
  expect_equal(f$depth_labeled, 3L)
  expect_equal(f$data_type, "number")
  expect_equal(f$semantic_type, "measurement")
})

test_that("a non-prefix gap does not inflate depth", {
  # semantic_type present but semantic_family missing is NOT a valid depth-3 path
  f <- fx_dgf_fields("number", NA, "measurement")
  expect_equal(f$depth_labeled, 1L)
})
