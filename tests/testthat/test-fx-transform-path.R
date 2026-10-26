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

test_that("a unit change with no registered converter is not transformable", {
  p <- fx_plan_transform(fx_format("year", "FYyyyy", "fiscal"),
                         fx_format("year", "bare", "calendar"))
  expect_false(p$transformable)
  expect_match(p$reason, "no path")
})
