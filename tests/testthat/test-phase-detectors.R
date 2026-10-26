# v7 detector wiring: day_of_week / month_of_year gain selective, detector-backed
# recipes (as_dow / as_moy); first_name / quarter / domain were already selective
# and had their implemented flag reconciled.

test_that("as_dow / as_moy map names to numeric position, NA otherwise", {
  expect_equal(fx_transform(c("Mon", "Friday", "banana"), "{{ as_dow }}"), c("1", "5", NA))
  expect_equal(fx_transform(c("Jan", "December", "banana"), "{{ as_moy }}"), c("1", "12", NA))
})

test_that("fx_stabilize resolves the phase leaves to numeric position", {
  expect_equal(fx_stabilize(c("Mon", "Fri", "Sun"), "day_of_week")$stable, c("1", "5", "7"))
  expect_equal(fx_stabilize(c("Jan", "Jul", "Dec"), "month_of_year")$stable, c("1", "7", "12"))
})

test_that("guess_data_type resolves the newly-wired leaves to depth 4", {
  expect_equal(guess_data_type(c("Mon","Tue","Wed","Thu","Fri","Mon"))$route$semantic_type, "day_of_week")
  expect_equal(guess_data_type(c("Jan","Feb","Mar","Apr","Jul","Sep"))$route$semantic_type, "month_of_year")
  expect_equal(guess_data_type(c("2019Q1","2019Q2","2019Q3","2020Q1"))$route$semantic_type, "quarter")
})

test_that("the wired variants are marked implemented in the ontology", {
  o <- fx_ontology()
  wired <- c("n0027-f01","n0063-f01","n0067-f01","n0068-f01","n0035-f01")
  expect_true(all(o$implemented[o$variant_id %in% wired] == "yes"))
})
