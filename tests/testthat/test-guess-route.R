# guess_data_type()'s v6 router->verifier record ($route). The router shortlists
# ontology candidates by signature; the verifier confirms a leaf only when a
# recipe is SELECTIVE (confirms the column, rejects a junk foil), otherwise the
# result gracefully truncates to the depth the router agrees on.

# Pin the deterministic signature router so these verifier/truncation tests do
# not depend on the retrainable learned model (which has its own coverage in
# test-fx-router.R). Confirmable leaves resolve identically under both routers.
rt <- function(x, ...) guess_data_type(x, router = "signature", ...)$route

test_that("legacy fields are preserved alongside the route record", {
  g <- guess_data_type(c("USD", "EUR", "JPY", "GBP"))
  expect_equal(g$guess, "currency_code")                 # unchanged contract
  expect_true(all(c("data_type", "semantic_type", "format_label", "depth",
                    "confidence", "candidates") %in% names(g$route)))
  expect_null(guess_data_type(c("USD", "EUR"), route = FALSE)$route)
})

test_that("selective recipes resolve a full leaf (depth 4)", {
  r <- rt(c("California", "TX", "Ohio", "New York", "FL"))
  expect_equal(r$semantic_type, "geographic")
  expect_equal(r$format_label,  "us_state")
  expect_equal(r$depth, 4L)

  r2 <- rt(c("isbn 0395629764", "ISBN 957-33-0471-6", "0-19-852663-6"))
  expect_equal(r2$semantic_type, "administrative")
  expect_equal(r2$format_label,  "isbn")

  r3 <- rt(c("James Smith", "Maria Garcia", "Robert Johnson", "Priscilla Ramos"))
  expect_equal(r3$semantic_type, "person")
})

test_that("temporal disambiguation keys on the raw column's time content", {
  expect_equal(rt(c("03/15/2019", "12/31/2020", "01/01/2021"))$semantic_type, "calendar")
  expect_equal(rt(c("2020-09-12T10:50:39", "2019-01-02T00:00:00"))$semantic_type, "timestamp")
  expect_equal(rt(c("14:30:00", "09:15:45", "23:59:59"))$semantic_type, "clock")
})

test_that("non-selective columns truncate instead of claiming a false leaf", {
  # free text: no recipe is selective -> stay at the text data_type, no format
  ft <- rt(c("the quick brown fox", "lorem ipsum dolor", "hello world foo"))
  expect_equal(ft$data_type, "text")
  expect_true(is.na(ft$format_label))
  expect_true(ft$depth <= 3L)

  # numeric subtype is not value-distinguishable -> truncate to number
  usd <- rt(c("$1,234.50", "$99.00", "$12.30", "$5000"))
  expect_equal(usd$data_type, "number")
  expect_true(is.na(usd$format_label))
})
