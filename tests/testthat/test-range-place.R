# v7 detector wiring, batch 2: min_max range and place.

test_that("min_max range resolves to a leaf and the recipe is selective", {
  expect_equal(guess_data_type(c("1.2, 3.4","5 to 9","3.4, 7.8","10 to 20"))$route$semantic_type,
               "min_max")
  # as_range validates range shape (low leak on the junk foil)
  expect_true(all(!is.na(fx_transform(c("1.2, 3.4", "5 to 9"), "{{ as_range }}"))))
  expect_true(is.na(fx_transform("banana", "{{ as_range }}")))
})

test_that("place uses a selective lookup recipe (maps names, rejects non-places)", {
  # a place name maps to canonical; a non-place is NA -> this is what makes the
  # recipe confirmable (vs the old {{ none }} that passed everything through)
  expect_equal(fx_stabilize(c("Chicago", "Boston"), "place")$stable, c("Chicago", "Boston"))
  expect_true(is.na(fx_transform("zzxqwt", "lookup:place")))
  # note: a city COLUMN may route to the geographic leaf rather than place --
  # semantic_type "geographic" and "place" legitimately overlap for city names
  # (a documented ontology collision); we assert the recipe, not the tie-break.
})

test_that("batch-2 variants are marked implemented", {
  o <- fx_ontology()
  expect_true(all(o$implemented[o$variant_id %in% c("n0029-f01","n0016-f01")] == "yes"))
})
