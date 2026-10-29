# Regression: base R strptime() aborts with "input string is too long" on
# values over 1000 bytes. The date machinery loops strptime() over raw cell
# values, so a single over-long free-text value used to crash is_date(),
# guess_data_type() and fx_stabilize(). Over-long values must be treated as
# non-dates instead. (datagoodr dev note: degenerate-columns-and-preflight, B2.)

long_val <- paste(rep("a", 1500L), collapse = "")   # 1500 bytes, > strptime's limit

test_that("is_date() does not crash on an over-long value and treats it as non-date", {
  x <- c("2019-03-15", long_val, "banana", NA)
  expect_silent(res <- is_date(x))
  expect_equal(res, c(TRUE, FALSE, FALSE, NA))
})

test_that("guess_data_type() does not crash on a column containing an over-long value", {
  x <- c("Reasonable cause statement:", long_val, "see attached narrative",
         "details provided upon request")
  expect_error(guess_data_type(x), NA)
})

test_that("fx_stabilize() does not crash when a date column carries an over-long value", {
  x <- c("2019-03-15", "2020-12-31", long_val)
  expect_error(out <- fx_stabilize(x, "calendar"), NA)
  # the two real dates still stabilize; the over-long value is dropped to NA
  expect_equal(out$rendered[1:2], c("2019-03-15", "2020-12-31"))
  expect_true(is.na(out$rendered[3]))
})

test_that("a value at the strptime byte limit is still screened out", {
  # 1000-byte value: base strptime tolerates exactly 1000 but not more; the
  # guard rejects it regardless, since no real date is near this length.
  thousand <- paste(rep("b", 1000L), collapse = "")
  expect_silent(res <- is_date(c("2019-03-15", thousand)))
  expect_equal(res, c(TRUE, FALSE))
})
