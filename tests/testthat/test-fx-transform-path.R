test_that("a unit change is transformable when a converter is registered", {
  p <- fx_plan_transform(fx_format("temperature", "celsius", "C"),
                         fx_format("temperature", "fahrenheit", "F"))
  expect_true(p$transformable)
  expect_equal(vapply(p$path, `[[`, "", "name"),
               c("read_celsius", "convert_C_F", "write_fahrenheit"))
  expect_equal(fx_apply_plan("20 C", p), "68 F")
})

test_that("a reformat with no unit change is transformable", {
  p <- fx_plan_transform(fx_format("calendar", "mdy_slash"),
                         fx_format("calendar", "ymd_dash"))
  expect_true(p$transformable)
  expect_equal(fx_apply_plan("03/15/2019", p), "2019-03-15")
})

test_that("identity is a transformable empty path", {
  p <- fx_plan_transform(fx_format("calendar", "ymd_dash"),
                         fx_format("calendar", "ymd_dash"))
  expect_true(p$transformable)
  expect_length(p$path, 0)
})

test_that("the registry is generated from the ontology (read_ edges)", {
  # an ontology leaf's written style parses to canonical via a generated edge
  p <- fx_plan_transform(fx_format("email", "email"), fx_format("email"))
  expect_true(p$transformable)
  expect_equal(fx_apply_plan("Jane@Example.ORG", p), "jane@example.org")
  # the registry carries far more than the hand-authored seed
  expect_gt(length(fx_transforms()), length(formex:::.fx_seed_transforms()))
})

test_that("a date renders to any written style, and styles inter-convert", {
  expect_equal(fx_apply_plan("2019-03-15",
    fx_plan_transform(fx_format("calendar"), fx_format("calendar","mdy_slash"))), "03/15/2019")
  expect_equal(fx_apply_plan("2019-03-15",
    fx_plan_transform(fx_format("calendar"), fx_format("calendar","dmy_slash"))), "15/03/2019")
  expect_equal(fx_apply_plan("2019-03-15",
    fx_plan_transform(fx_format("calendar"), fx_format("calendar","mon_mdy"))), "Mar 15, 2019")
  # US -> EU restyle (read one style, write another)
  expect_equal(fx_apply_plan("03/15/2019",
    fx_plan_transform(fx_format("calendar","mdy_slash"), fx_format("calendar","dmy_slash"))), "15/03/2019")
})

test_that("a unit change with no registered converter is not transformable", {
  p <- fx_plan_transform(fx_format("year", "FYyyyy", "fiscal"),
                         fx_format("year", "bare", "calendar"))
  expect_false(p$transformable)
  expect_match(p$reason, "no path")
})
