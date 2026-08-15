# Evaluation harness: evaluate_columns() + eval_summary() scored against a small
# synthetic labeled corpus with an inline crosswalk. Exercises the same machinery
# the Sherlock run uses (data-raw/eval/), so the harness is verified without the
# external download.

cw <- rbind(
  data.frame(source_label = "email",  data_type = "text",        data_subtype = "token",      data_class = "email"),
  data.frame(source_label = "city",   data_type = "categorical", data_subtype = "nominal",    data_class = "geography"),
  data.frame(source_label = "weight", data_type = "number",      data_subtype = "continuous", data_class = "measurement"),
  data.frame(source_label = "rate",   data_type = "number",      data_subtype = "continuous", data_class = "rate"),
  stringsAsFactors = FALSE)

test_that("value-only eval: detectable classes hit, metadata-gated classes miss", {
  cols <- list(
    c("a@b.com", "c@d.org", "e@f.net"), c("g@h.com", "i@j.io"),   # email x2
    c("Chicago", "Boston", "Seattle"),  c("Denver", "Miami"),      # city  x2
    c("70.5", "82.1", "64.0"),          c("55.2", "91.7"))         # weight x2 (no value signature)
  labels <- c("email", "email", "city", "city", "weight", "weight")

  res <- evaluate_columns(cols, labels, cw)      # use_name = FALSE
  expect_equal(nrow(res), 6)
  expect_true(all(res$in_scope))

  # email + city recognized by value detectors; weight is metadata-gated -> missed
  expect_true(all(res$class_correct[res$label %in% c("email", "city")]))
  expect_false(any(res$class_correct[res$label == "weight"]))
  expect_true(all(is.na(res$pred_class[res$label == "weight"])))

  sm <- eval_summary(res)
  expect_equal(sm$overall$class_accuracy, 4 / 6)
  expect_equal(sm$by_class$recall[sm$by_class$gold_class == "email"], 1)
  expect_equal(sm$by_class$recall[sm$by_class$gold_class == "geography"], 1)
  expect_equal(sm$by_class$recall[sm$by_class$gold_class == "measurement"], 0)
})

test_that("name-mode eval recovers a metadata-gated class from the header", {
  cols   <- list(c("3.4", "5.1", "7.8"), c("2.2", "9.9"))
  labels <- c("rate", "rate")
  hdrs   <- c("unemployment_rate", "response_rate")

  res <- evaluate_columns(cols, labels, cw, headers = hdrs, use_name = TRUE)
  expect_true(all(res$class_correct))          # name side supplies 'rate'
  expect_true(all(res$source == "name"))       # and it came from the name, not values
})

test_that(".crosswalk_lookup is case/space/punctuation insensitive", {
  big <- rbind(cw, data.frame(source_label = "birth date", data_type = "temporal",
    data_subtype = "point", data_class = "calendar_date", stringsAsFactors = FALSE))
  expect_equal(unname(formex:::.crosswalk_lookup("BirthDate", big)["class"]), "calendar_date")
  expect_equal(unname(formex:::.crosswalk_lookup("birth_date", big)["class"]), "calendar_date")
  expect_true(is.na(formex:::.crosswalk_lookup("nonexistent", big)["class"]))
})
