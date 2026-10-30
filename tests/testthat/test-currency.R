# Currency data-type detectors. Two layers of assertions:
#   * spot checks  -- seed-independent, pin the contract of each detector.
#   * fixture recall/precision -- run each detector over the frozen
#     data_type_tests fixture; positives must all pass, and the aggressive
#     mutation tiers (S3 random, SP scramble) must be rejected at a high rate.
# The S1 tier is intentionally NOT asserted: for loosely-structured types it
# mutates only digits and regenerates valid amounts (AutoType's Section 6
# caveat), so it is not a meaningful negative here.

test_that("is_currency_amount keys on a symbol; bare numbers are not currency", {
  expect_equal(is_currency_amount(c("$2300.00", "17,298$", "-45€", "$1,000", "€ 17.298")),
               rep(TRUE, 5))
  expect_equal(is_currency_amount(c("1234", "-45.10", "banana", "$", "")),
               rep(FALSE, 5))
  expect_true(is.na(is_currency_amount(NA)))
})

test_that("the usd recipe is selective and strips to a bare number", {
  expect_equal(fx_transform(c("$2300.00", "17,298$", "$-45"), "{{ as_usd }}"),
               c("2300", "17298", "-45"))
  expect_true(all(is.na(fx_transform(c("1234", "banana"), "{{ as_usd }}"))))  # no symbol -> NA
  expect_equal(guess_data_type(c("$2300.00","$-45","$1,000","$99.50","$12","$450"))$route$semantic_type,
               "usd")
})

test_that("the euro recipe is selective (EU format) and rejects dollars", {
  eu <- intToUtf8(0x20acL)
  expect_equal(fx_transform(c(paste0("2.300,00", eu), paste0(eu, " 17.298"),
                              paste0("-45,10", eu)), "{{ as_euro }}"),
               c("2300", "17298", "-45.1"))
  expect_true(all(is.na(fx_transform(c("$2300.00", "1234"), "{{ as_euro }}"))))  # not euro -> NA
  euro_col <- paste0(formatC(c(13570.28, 17476.08, 250, 99.99, 1000, -45.1),
                             format = "f", digits = 2, big.mark = ".",
                             decimal.mark = ","), eu)
  expect_equal(guess_data_type(euro_col)$route$semantic_type, "euro")
})

test_that("is_currency_code is an ISO 4217 lookup", {
  expect_equal(is_currency_code(c("USD", "eur", "ZZZ")),
               c(TRUE, TRUE, FALSE))                 # case-insensitive lookup
  expect_true(is.na(is_currency_code(NA)))           # NA propagates
  expect_false(is_currency_code("US"))               # wrong length
})

test_that("is_currency_symbol checks symbol + bounded-decimal amount", {
  expect_true(all(is_currency_symbol(c("$12.30", "€299.10", "¥19", "£1222"))))
  expect_false(is_currency_symbol("$1,000"))         # no thousands separators
  expect_false(is_currency_symbol("$1.234"))         # at most two decimals
  expect_false(is_currency_symbol("$"))              # symbol needs an amount
  expect_false(is_currency_symbol("12.30"))          # amount needs a symbol
  expect_true(is.na(is_currency_symbol(NA)))
})

test_that("is_currency_code_symbol needs a real code, symbol, and amount", {
  expect_true(all(is_currency_code_symbol(c("USD$12.30", "EUR€299.10", "JPY¥22"))))
  expect_false(is_currency_code_symbol("ZZZ$1"))     # syntactic but not a real code
  expect_false(is_currency_code_symbol("USD 10"))    # missing symbol
  expect_false(is_currency_code_symbol("$12.30"))    # missing code
  expect_true(is.na(is_currency_code_symbol(NA)))
})

test_that("every valid fixture case passes its own detector (recall = 1)", {
  detectors <- list(
    currency_code        = is_currency_code,
    currency_symbol      = is_currency_symbol,
    currency_code_symbol = is_currency_code_symbol
  )
  for (nm in names(detectors)) {
    df <- data_type_tests[[nm]]
    valid <- df$case[df$label == "valid"]
    expect_true(all(detectors[[nm]](valid)),
                info = paste("valid cases rejected for", nm))
  }
})

test_that("aggressive negative tiers (S3, SP) are mostly rejected", {
  detectors <- list(
    currency_code        = is_currency_code,
    currency_symbol      = is_currency_symbol,
    currency_code_symbol = is_currency_code_symbol
  )
  for (nm in names(detectors)) {
    df <- data_type_tests[[nm]]
    for (tier in c("S3", "SP")) {
      cases <- df$case[df$label == tier]
      if (length(cases) == 0) next          # e.g. SP is empty for codes
      pass_rate <- mean(detectors[[nm]](cases), na.rm = TRUE)
      expect_lt(pass_rate, 0.15)            # near-zero leakage expected
    }
  }
})

test_that("guess_data_type picks the right type for a clean column", {
  expect_equal(guess_data_type(c("USD", "EUR", "JPY", "GBP", "CAD"))$guess,
               "currency_code")
  expect_equal(guess_data_type(c("$12.30", "€5.50", "£49.99", "¥5000"))$guess,
               "currency_symbol")
  expect_equal(guess_data_type(c("USD$1", "EUR€21", "JPY¥22"))$guess,
               "currency_code_symbol")
})

test_that("guess_data_type returns NA when nothing clears the threshold", {
  res <- guess_data_type(c("apple", "banana", "cherry"))
  expect_true(is.na(res$guess))
})
