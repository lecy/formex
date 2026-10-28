# Multi-style detection: $route reports the calendar column's actual written
# style (order + separator), not the generic "calendar" label.

test_that("guess_data_type reports the detected date style", {
  st <- function(x) guess_data_type(x)$route$format_style
  expect_equal(st(c("03/15/2019","12/31/2020","01/05/2021","07/04/2020")), "mdy_slash")
  expect_equal(st(c("15/03/2019","31/12/2020","25/01/2021","04/07/2020")), "dmy_slash")
  expect_equal(st(c("2019-03-15","2020-12-31","2021-01-05")), "ymd_dash")
  expect_equal(st(c("Mar 15, 2019","Dec 31, 2020","Jan 5, 2021")), "mon_mdy")
  # all parts <= 12 is ambiguous -> default to the US mdy convention
  expect_equal(st(c("03/04/2019","05/06/2020","01/02/2021")), "mdy_slash")
})

test_that("a detected style round-trips through the write renderers", {
  x <- c("15/03/2019","31/12/2020")                 # EU
  expect_equal(guess_data_type(x)$route$format_style, "dmy_slash")
  expect_equal(fx_stabilize(x, "calendar", target_format = "mdy_slash")$rendered,
               c("03/15/2019","12/31/2020"))
})
