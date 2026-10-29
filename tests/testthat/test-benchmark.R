# The benchmark harness: scores guess_data_type() over the packaged mini set at
# every ontology level, records runtime, and reports the shape of errors.

test_that("fx_benchmark_data ships the packaged mini set", {
  d <- fx_benchmark_data("mini")
  expect_s3_class(d, "data.frame")
  expect_gt(nrow(d), 0)
  expect_true(all(c("case_id", "tier", "data_type", "semantic_family",
                    "semantic_type", "variant_id", "values", "gold_style",
                    "gold_unit") %in% names(d)))
  expect_type(d$values, "list")
  expect_true(all(c("clean", "sherlock") %in% unique(d$tier)) ||
              length(unique(d$tier)) >= 1)
})

test_that("fx_benchmark returns a scored, timed row per case", {
  d   <- fx_benchmark_data("mini")
  sub <- d[d$data_type %in% c("temporal", "categorical", "text"), ][1:18, ]
  res <- fx_benchmark(sub)
  expect_equal(nrow(res), nrow(sub))
  expect_true(all(c("gold_data_type", "pred_data_type", "dt_correct",
                    "type_correct", "headline", "outcome", "depth",
                    "confidence", "elapsed_sec") %in% names(res)))
  expect_true(all(res$outcome %in% c("hit", "graceful", "misroute")))
  expect_true(all(res$elapsed_sec >= 0))
  expect_true(all(res$headline[!is.na(res$headline)] >= 0 &
                  res$headline[!is.na(res$headline)] <= 1))
})

test_that("synthetic temporal cases route correctly (regression floor)", {
  d   <- fx_benchmark_data("mini")
  tmp <- d[d$data_type == "temporal", ]
  skip_if(nrow(tmp) == 0)
  res <- fx_benchmark(tmp)
  # the synthetic temporal bank is exact ground truth -> data_type must be perfect
  expect_equal(mean(res$dt_correct), 1)
})

test_that("summary, confusion and coverage-gap reports have the right shape", {
  d   <- fx_benchmark_data("mini")
  res <- fx_benchmark(d[1:40, ])

  s <- fx_benchmark_summary(res)
  expect_true(all(c("overall", "by_data_type", "runtime") %in% names(s)))
  expect_true(all(c("acc_data_type", "acc_type", "headline", "hit", "graceful",
                    "misroute") %in% names(s$overall)))
  expect_true(all(c("total_sec", "median_sec", "p95_sec") %in% names(s$runtime)))

  cm <- fx_benchmark_confusion(res, level = "data_type")
  expect_true(is.table(cm$matrix))
  expect_true(all(c("gold", "predicted", "prop") %in% names(cm$wrong_shape)) ||
              is.null(cm$wrong_shape))
  expect_true(all(c("hit", "graceful", "misroute") %in% names(cm$outcome)))

  gaps <- fx_coverage_gaps(res)
  expect_true(all(c("gold_variant_id", "support", "acc_type", "flag") %in%
                  names(gaps)))
  expect_true(all(gaps$flag %in% c("ok", "low-support", "low-accuracy")))
})

test_that("comparing a run against itself yields zero deltas", {
  d   <- fx_benchmark_data("mini")
  res <- fx_benchmark(d[1:24, ])
  cmp <- fx_benchmark_compare(res, res)
  expect_true(all(abs(cmp$overall$delta) < 1e-9))
  expect_true(all(abs(cmp$by_data_type$delta) < 1e-9, na.rm = TRUE))
})
