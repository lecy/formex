# The disambiguator: declared tie-break rules for the ontology's path
# collisions, and the pure rule that applies them.

test_that("the ontology declares a rule for every path collision", {
  o <- fx_ontology()
  # fx_validate_ontology fails on an UNdeclared collision; a clean ontology
  # means geographic carries a disambiguator and mixed no longer collides.
  expect_length(fx_validate_ontology(o), 0)
  geo <- o[o$semantic_type == "geographic", ]
  expect_true(all(nzchar(geo$disambiguator)))
  expect_setequal(unique(geo$disambiguator),
                  c("cardinality:repeating", "cardinality:unique"))
  # the unknown "mixed" leaf was renamed; only the boolean one keeps the name
  expect_false("heterogeneous" %in% o$semantic_type[o$data_type == "boolean"])
  expect_equal(o$data_type[o$semantic_type == "heterogeneous"], "unknown")
})

test_that("the validator rejects an undeclared collision", {
  o <- fx_ontology()
  o$disambiguator[o$semantic_type == "geographic"] <- ""   # strip the rule
  expect_true(any(grepl("path collision", fx_validate_ontology(o))))
})

test_that("cardinality disambiguates geographic end to end", {
  # same FIPS values repeating across rows -> a grouping (categorical)
  rep_fips <- guess_data_type(c("06037","36061","06037","17031","36061","06037","17031","06037"))$route
  expect_equal(rep_fips$data_type, "categorical")
  expect_equal(rep_fips$semantic_type, "geographic")
  # unique FIPS per row -> a key (identifier)
  uniq_fips <- guess_data_type(c("06037","36061","17031","48201","53033","04013","12086","25017"))$route
  expect_equal(uniq_fips$data_type, "identifier")
  expect_equal(uniq_fips$semantic_type, "geographic")
  # a random 5-digit number is not a valid FIPS -> not geographic at all
  expect_false(isTRUE(guess_data_type(c("12309","88421","55012","73418","29100","61234"))$route$semantic_type == "geographic"))
})

test_that(".fx_disambiguate applies the cardinality rule", {
  rows <- data.frame(
    variant_id = c("cat", "id"),
    disambiguator = c("cardinality:repeating", "cardinality:unique"),
    stringsAsFactors = FALSE)
  expect_equal(formex:::.fx_disambiguate(rows, uniq = 1.00), 2L)  # unique -> the key
  expect_equal(formex:::.fx_disambiguate(rows, uniq = 0.20), 1L)  # repeats -> the grouping
  expect_true(is.na(formex:::.fx_disambiguate(rows, uniq = NA)))  # no signal -> unresolved
  # a non-cardinality collision does not resolve via this rule
  rows2 <- data.frame(disambiguator = c("name_hint", "name_hint"), stringsAsFactors = FALSE)
  expect_true(is.na(formex:::.fx_disambiguate(rows2, uniq = 1.00)))
})
