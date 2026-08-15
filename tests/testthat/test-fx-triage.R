# Field-quality triage: the gate before banking.

test_that("corrupted (mojibake) columns are excluded as garbage", {
  x <- c(rep("¿", 20), "true¿", "=¿")   # the GitTables ¿ pattern
  t <- fx_triage_field(x)
  expect_equal(t$verdict, "garbage")
  expect_false(t$keep)
})

test_that("empty / degenerate columns are excluded", {
  expect_equal(fx_triage_field(rep("N/A", 12))$verdict, "empty")   # all-sentinel
  expect_equal(fx_triage_field(rep("x", 20))$verdict, "empty")     # constant
  expect_equal(fx_triage_field(letters[1:5])$verdict, "empty")     # too few
})

test_that("label-vs-value mismatch is banked but flagged", {
  x <- c("Surgical Resection","Lavage","Needle Core Biopsy","Excision",
         "Aspiration","Resection","Biopsy","Lavage","Excision","Biopsy")
  t <- fx_triage_field(x, expected_data_type = "number")   # label says number, values text
  expect_equal(t$verdict, "mismatch")
  expect_true(t$keep)
  expect_match(t$reasons, "non-numeric")
})

test_that("clean fields are kept and difficulty-rated", {
  x <- c("2020-01-01","2020-02-15","2019-12-31","2021-06-30","2020-11-11",
         "2018-03-03","2022-08-08","2020-05-05","2019-09-09","2021-01-01")
  t <- fx_triage_field(x, expected_data_type = "temporal")
  expect_true(t$keep)
  expect_true(t$verdict %in% c("clean","hard"))
  expect_true(t$difficulty %in% c("easy","medium","hard"))
})
