# Ontology integrity (INTEGRATION §4). These invariants keep banked cases valid
# across ontology versions; a violation invalidates the archive, so they run in
# R CMD check.

test_that("shipped ontology passes every integrity check", {
  expect_equal(fx_validate_ontology(), character(0))
})

test_that("identity invariants hold row-by-row", {
  o <- fx_ontology()
  expect_false(any(duplicated(o$variant_id)))                       # unique variant_id
  expect_identical(o$node_label, formex:::.fx_derive_node_label(o)) # derived label rule
  # semantic_type_id <-> path is a bijection
  path <- paste(o$data_type, o$semantic_family, o$semantic_type, sep = "/")
  expect_true(all(tapply(o$semantic_type_id, path, function(z) length(unique(z))) == 1))
  expect_true(all(tapply(path, o$semantic_type_id, function(z) length(unique(z))) == 1))
  # every superseded_by target exists
  tgt <- unlist(strsplit(o$superseded_by[nzchar(o$superseded_by)], " *;; *"))
  expect_true(all(tgt %in% o$semantic_type_id))
})

test_that("the validator actually catches a break (renumbered id)", {
  o <- fx_ontology(); o$semantic_type_id[1] <- o$semantic_type_id[2]  # collide ids
  expect_gt(length(fx_validate_ontology(o)), 0)
})

test_that("extdata CSV and the lazy-loaded data object agree", {
  expect_equal(fx_ontology(), ontology)
})
