# feasibility_score(): path score 0/1/2 against the feasible ceiling, plus the
# independent unit-recovery flag.

test_that("reaching the feasible terminal node scores 0", {
  # birth date: ideal temporal/date/calendar, subclass feasible (depth 3)
  s <- feasibility_score(c("temporal","date","calendar"),
                         c("temporal","date","calendar"), 3)
  expect_equal(s$score, 0L)
  # weight: ideal .../measurement, but only class (quantity) is feasible (depth 2)
  s2 <- feasibility_score(c("number","quantity", NA),
                          c("number","quantity","measurement"), 2)
  expect_equal(s2$score, 0L)          # quantity IS the ceiling -> 0, not penalized
})

test_that("correct path but short of the ceiling scores 1", {
  # got temporal/date but not the calendar terminal (ceiling depth 3)
  s <- feasibility_score(c("temporal","date", NA),
                         c("temporal","date","calendar"), 3)
  expect_equal(s$score, 1L)
  # weight: only reached type(number), class(quantity) was feasible
  s2 <- feasibility_score(c("number", NA, NA),
                          c("number","quantity","measurement"), 2)
  expect_equal(s2$score, 1L)
})

test_that("wrong branch or no hit scores 2", {
  expect_equal(feasibility_score(c("number","quantity","count"),
                                 c("temporal","date","calendar"), 3)$score, 2L)
  expect_equal(feasibility_score(c(NA,NA,NA),
                                 c("number","quantity","measurement"), 2)$score, 2L)
})

test_that("NULL target: abstaining is correct (0), guessing is wrong (2)", {
  expect_equal(feasibility_score(c(NA,NA,NA), c("","",""), 0)$score, 0L)
  expect_equal(feasibility_score(c("text","name","person"), c("","",""), 0)$score, 2L)
})

test_that("feasible_depth 0 (year): any on-path hit is 0, a miss is 2", {
  ideal <- c("temporal","period","year")
  expect_equal(feasibility_score(ideal, ideal, 0)$score, 0L)          # detected -> bonus
  expect_equal(feasibility_score(c("number","quantity",NA), ideal, 0)$score, 2L) # off branch
  expect_equal(feasibility_score(c(NA,NA,NA), ideal, 0)$score, 2L)    # abstained
})

test_that("unit_recovered is an independent axis", {
  base <- c("number","currency","usd")
  # subclass reached AND unit recovered (predictor emits the crosswalk unit token)
  s <- feasibility_score(base, base, 3, pred_unit="currency", ideal_unit="currency")
  expect_equal(s$score, 0L); expect_equal(s$unit_recovered, 1L)
  # subclass reached, unit NOT recovered (bare amount, no symbol)
  s2 <- feasibility_score(base, base, 3, pred_unit=NA, ideal_unit="currency")
  expect_equal(s2$score, 0L); expect_equal(s2$unit_recovered, 0L)
  # no unit for this type
  s3 <- feasibility_score(base, base, 3)
  expect_true(is.na(s3$unit_recovered))
})

test_that("score_feasibility_table scores row-aligned frames", {
  preds <- data.frame(
    type     = c("temporal","number","text"),
    class    = c("date","quantity", NA),
    subclass = c("calendar", NA, NA),
    unit     = c(NA, NA, NA), stringsAsFactors=FALSE)
  cw <- data.frame(
    v4_type=c("temporal","number","categorical"),
    v4_class=c("date","quantity","mutually_exclusive"),
    v4_subclass=c("calendar","measurement","unordered"),
    feasible_depth=c(3,2,2), unit=c(NA,NA,NA), stringsAsFactors=FALSE)
  out <- score_feasibility_table(preds, cw)
  expect_equal(out$score, c(0L, 0L, 2L))   # calendar=ceiling; quantity=ceiling; text!=categorical
})
