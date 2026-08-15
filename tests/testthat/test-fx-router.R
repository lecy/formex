# Learned router (R/21-fx-router.R). These tests exercise the SHORTLIST plumbing
# and the graceful fallback; they must pass whether or not the trained artifact
# (inst/extdata/router_xgb.rds) and xgboost happen to be installed.

test_that("the signature router always yields a usable shortlist", {
  ont <- fx_ontology()
  sl <- .fx_shortlist(c("California", "TX", "Ohio"), ont, k = 8, prefer = "signature")
  expect_s3_class(sl, "data.frame")
  expect_true(all(c("semantic_type_id", "data_type", "semantic_family",
                    "semantic_type", "router_sim") %in% names(sl)))
  expect_identical(attr(sl, "router"), "signature")
  expect_lte(nrow(sl), 8L)
})

test_that("router='signature' forces the model-free path and still resolves leaves", {
  r <- guess_data_type(c("03/15/2019", "12/31/2020", "01/01/2021"),
                       router = "signature")$route
  expect_identical(r$router_method, "signature")
  expect_equal(r$semantic_type, "calendar")
})

test_that("router='auto' degrades to signature when no learned model is present", {
  # if xgboost/artifact are absent, auto must silently fall back, never error
  r <- guess_data_type(c("France", "Germany", "Japan"), router = "auto")$route
  expect_true(r$router_method %in% c("learned", "signature"))
  expect_false(is.na(r$data_type))
})

test_that("a learned artifact, when present, loads and routes", {
  # the artifact only loads when xgboost is installed AND the model ships, so
  # guarding on it alone also covers the xgboost precondition
  art <- .fx_router_artifact()
  skip_if(is.null(art), "xgboost or trained router artifact unavailable")
  expect_true(length(art$levels) > 1 && length(art$features) > 100)
  r <- guess_data_type(c("James Smith", "Maria Garcia", "Robert Johnson"),
                       router = "learned")$route
  expect_identical(r$router_method, "learned")
  expect_false(is.na(r$data_type))
})
