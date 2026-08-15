# Variable-name classifier: header tokenizer, classify_by_name() lexicon
# matching, and the values-first guess_column() reconciler. Also a conformance
# check that every lexicon coordinate is a real ontology-catalog class.

test_that(".tokenize_name normalizes camelCase, snake, and punctuation", {
  expect_equal(formex:::.tokenize_name("hourlyWage"), "hourly wage")
  expect_equal(formex:::.tokenize_name("respondent_weight"), "respondent weight")
  expect_equal(formex:::.tokenize_name("Std.Err (2019)"), "std err 2019")
  expect_equal(formex:::.tokenize_name("FIPS_Code"), "fips code")
})

test_that("classify_by_name reaches metadata-gated numeric classes", {
  expect_equal(classify_by_name("sampling_weight")$guess, "weight")
  expect_equal(classify_by_name("hourly_wage")$guess,     "currency")
  expect_equal(classify_by_name("unemployment_rate")$guess, "rate")
  expect_equal(classify_by_name("std_err")$guess,          "standard_error")
  expect_equal(classify_by_name("poverty_percentile")$guess, "percentile")
  expect_equal(classify_by_name("latitude")$guess,         "coordinate")
})

test_that("classify_by_name reaches boolean roles and ordinals", {
  expect_equal(classify_by_name("is_active")$guess,       "indicator")
  expect_equal(classify_by_name("eligible")$guess,        "eligibility")
  expect_equal(classify_by_name("likert_agree")$guess,    "likert")
  expect_equal(classify_by_name("treatment_arm")$guess,   "group")
})

test_that("classify_by_name breaks ties by confidence, not just first match", {
  # "z score" hits both standardized_score (0.82) and score (0.62)
  expect_equal(classify_by_name("baseline_z_score")$guess, "standardized_score")
  # "response rate" hits rate (0.68) and response (0.66)
  expect_equal(classify_by_name("response_rate")$guess, "rate")
  # both candidates are surfaced for inspection
  expect_true(nrow(classify_by_name("response_rate")$candidates) >= 2)
})

test_that("classify_by_name is safe on empty / unmatched / NA headers", {
  expect_true(is.na(classify_by_name(NA)$guess))
  expect_true(is.na(classify_by_name("")$guess))
  expect_true(is.na(classify_by_name("xqz_blob_42")$guess))
  expect_equal(unname(classify_by_name("wt")$ontology[["data_format"]]), NA_character_)
})

test_that("guess_column is values-first: a real value signature wins", {
  # county FIPS values win even though the name would say 'geography' anyway...
  g1 <- guess_column(c("06037", "36061", "48201"), name = "county")
  expect_equal(g1$source, "value")
  expect_equal(g1$guess, "county_fips")

  # ...and a MISLEADING name cannot override a value signature
  g2 <- guess_column(c("a.b@x.com", "c@y.org", "d@z.net"), name = "weight")
  expect_equal(g2$source, "value")
  expect_equal(g2$guess, "email")
})

test_that("guess_column falls back to the name when values are silent", {
  # bare doubles: no value detector fires -> the name supplies the class
  g <- guess_column(c("3.4", "5.1", "7.8", "2.2"), name = "sampling_weight")
  expect_equal(g$source, "name")
  expect_equal(g$guess, "weight")
  expect_equal(unname(g$ontology[["data_class"]]), "weight")
  expect_equal(unname(g$ontology[["data_type"]]),  "number")
})

test_that("guess_column returns 'none' when neither values nor name resolve", {
  g <- guess_column(c("3.4", "5.1", "7.8"), name = "xqz_blob_42")
  expect_equal(g$source, "none")
  expect_true(is.na(g$guess))
})

test_that("every name-lexicon coordinate is a valid catalog class", {
  csv <- NULL
  for (p in c("../../data-types/research_data_type_ontology.csv",
              "../../../data-types/research_data_type_ontology.csv",
              "data-types/research_data_type_ontology.csv")) {
    if (file.exists(p)) { csv <- p; break }
  }
  skip_if(is.null(csv), "ontology catalog CSV not available")

  d <- utils::read.csv(csv, stringsAsFactors = FALSE, check.names = FALSE)
  names(d)[1] <- sub("^﻿", "", names(d)[1])
  catalog <- unique(paste(d$data_type, d$data_subtype, d$data_class, sep = "/"))

  lex <- vapply(formex:::.name_lexicon,
                function(r) paste(r$coords, collapse = "/"), character(1))
  bad <- setdiff(unique(lex), catalog)
  expect_true(length(bad) == 0,
              info = paste("lexicon coords not in catalog:",
                           paste(bad, collapse = ", ")))
})
