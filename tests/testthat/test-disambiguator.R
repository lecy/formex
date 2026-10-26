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
