# Contract tests for the batch added after the geography/gov families:
# person-name gazetteers (first/last/full), the boolean indicator detector,
# WKT geometry, and the year-quarter / weekday / month-name temporal detectors.
# These are fixture-independent (they do not rely on data_type_tests) so they
# hold even before data-raw/build_test_cases.R is re-run.

test_that("is_first_name / is_last_name use the SSA/Census gazetteers", {
  expect_true(all(is_first_name(c("James", "olivia", "  Mary ", "NOAH"))))
  expect_true(all(is_last_name(c("Smith", "garcia", "Nguyen", "PATEL"))))
  expect_false(is_first_name("Xqzzybberd"))
  expect_false(is_last_name("Xqzzybberd"))
  expect_true(is.na(is_first_name(NA)))
  expect_true(is.na(is_last_name(NA)))
})

test_that("is_full_name accepts First-Last and Last-comma-First, rejects phrases", {
  expect_true(all(is_full_name(c("John Smith", "Mary Johnson", "Mary J. Cooper",
                                 "Smith, John", "Garcia, Maria"))))
  expect_false(is_full_name("New York"))       # neither token is a known name
  expect_false(is_full_name("Chicago"))        # single token
  expect_false(is_full_name("the quick brown fox jumps"))  # too many tokens
  expect_true(is.na(is_full_name(NA)))
})

test_that("is_boolean recognizes two-state tokens only", {
  expect_true(all(is_boolean(c("TRUE", "false", "T", "f", "Yes", "no",
                               "Y", "n", "1", "0"))))
  expect_false(is_boolean("maybe"))
  expect_false(is_boolean("2"))
  expect_true(is.na(is_boolean(NA)))
})

test_that("is_quarter matches year-quarter forms, bounds the quarter digit", {
  expect_true(all(is_quarter(c("2019Q1", "2019-Q4", "Q3 2020", "FY2018Q4"))))
  expect_false(is_quarter("2019Q5"))   # quarter out of range
  expect_false(is_quarter("2019"))     # no quarter
  expect_false(is_quarter("Q1"))       # no year
  expect_true(is.na(is_quarter(NA)))
})

test_that("weekday and month-name detectors match names, not numbers", {
  expect_true(all(is_day_of_week(c("Monday", "mon", "FRI", "Sunday"))))
  expect_false(is_day_of_week("Someday"))
  expect_false(is_day_of_week("3"))
  expect_true(all(is_month_of_year(c("January", "feb", "Aug", "December"))))
  expect_false(is_month_of_year("Smarch"))
  expect_false(is_month_of_year("13"))
})

test_that("is_wkt_geometry matches OGC WKT literals", {
  expect_true(all(is_wkt_geometry(c(
    "POINT (30 10)", "POINT(30 10)", "LINESTRING (0 0, 1 1)",
    "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))",
    "POINT Z (30 10 5)", "POINT EMPTY"))))
  expect_false(is_wkt_geometry("banana"))
  expect_false(is_wkt_geometry("POINT"))          # no coordinate body
  expect_true(is.na(is_wkt_geometry(NA)))
})

# --- integration: guess_data_type routes to the new ontology coordinates -----

test_that("guess_data_type types a full-name column via person_name", {
  g <- guess_data_type(c("John Smith", "Mary Johnson", "Robert Brown",
                         "Patricia Garcia", "Smith, John"),
                       name = "respondent_name")
  expect_equal(g$guess, "full_name")
  expect_equal(unname(g$ontology[["data_type"]]),  "text")
  expect_equal(unname(g$ontology[["data_class"]]), "person_name")
})

test_that("guess_data_type types a WKT column via geometry", {
  g <- guess_data_type(c("POINT (30 10)", "POINT (12 42)", "POINT (5 5)",
                         "LINESTRING (0 0, 1 1)"), name = "geom")
  expect_equal(g$guess, "wkt_geometry")
  expect_equal(unname(g$ontology[["data_type"]]),  "structured")
  expect_equal(unname(g$ontology[["data_class"]]), "geometry")
})

test_that("guess_data_type types a boolean column", {
  g <- guess_data_type(c("Y", "N", "Y", "Y", "N"), name = "is_active")
  expect_equal(g$guess, "boolean")
  expect_equal(unname(g$ontology[["data_type"]]), "boolean")
})
