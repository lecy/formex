# Fixes surfaced by the political-org 527 registry (Form 8871).

test_that("an email column routes to contact/email, not domain/organization", {
  r <- guess_data_type(c("wfga@localaccess.com","no@email.com","a.b@x.org",
                         "jane@example.net","foo@bar.gov"))$route
  expect_equal(r$data_type, "text")
  expect_equal(r$semantic_type, "email")
  expect_equal(r$depth, 4L)
})

test_that("a 4-digit code is not zero-padded into a bogus county FIPS", {
  # 8871 -> 08871 has a valid state prefix (08=CO) but 871 is not a real county;
  # as_fips now requires a genuine 5-digit code, so a form-type column is not
  # mislabelled geographic.
  expect_true(is.na(fx_transform("8871", "{{ as_fips }}")))
  expect_equal(fx_transform("06037", "{{ as_fips }}"), "06037")
  r <- guess_data_type(rep(c("8871","8872"), 6))$route
  expect_false(isTRUE(r$semantic_type == "geographic"))
  # a real 5-digit FIPS column still resolves to geographic
  expect_equal(guess_data_type(c("06037","36061","06037","17031","36061","06037","17031"))$route$semantic_type,
               "geographic")
})
