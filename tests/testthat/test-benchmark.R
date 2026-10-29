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
  # scope to the exact-ground-truth generator only. The "scaffold" corpus
  # (deliberately-hard gap-fill cases, e.g. bare hour_of_day / week_of_year
  # integers) and the header-labelled "sherlock" temporal rows are NOT exact
  # ground truth and carry no 100% contract.
  tmp <- d[d$data_type == "temporal" & d$corpus == "synthetic_temporal", ]
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
  expect_true(all(c("gold_variant_id", "support", "acc_type", "match_kind",
                    "target", "wilson_upper", "bucket") %in% names(gaps)))
  expect_true(all(gaps$bucket %in%
                  c("needs-detector-work", "needs-cases", "excluded", "ok")))
})

test_that("fx_coverage_gaps is difficulty-aware: buckets, baseline, stress", {
  d   <- fx_benchmark_data("mini")
  res <- fx_benchmark(d)

  # a thin-support variant lands in needs-cases regardless of its accuracy
  g <- fx_coverage_gaps(res, min_support = 1000L)  # force everything thin
  expect_true(all(g$bucket == "needs-cases"))

  # header-gated match_kinds (shape/none) are excluded from the accuracy test,
  # never flagged "needs-detector-work" on value accuracy alone (present variants
  # only -- absent-variant surfacing is covered by its own test below)
  g2 <- fx_coverage_gaps(res, min_support = 1L, include_absent = FALSE)
  hg <- g2[!is.na(g2$match_kind) & g2$match_kind %in% c("shape", "none"), ]
  if (nrow(hg)) {
    expect_true(all(is.na(hg$target)))
    expect_true(all(hg$bucket %in% c("excluded", "ok")))
  }

  # a baseline that matches res exactly yields zero baseline_delta -> no
  # baseline-driven detector-work flag
  gb <- fx_coverage_gaps(res, baseline = res, min_support = 1L)
  expect_true(all(gb$baseline_delta[!is.na(gb$baseline_delta)] == 0))

  # supplying no baseline/stress leaves those columns present but NA
  expect_true(all(is.na(g2$baseline_delta)))
  expect_true(all(is.na(g2$stress_drop)))
})

test_that("fx_coverage_gaps surfaces live variants absent from the corpus", {
  d   <- fx_benchmark_data("mini")
  res <- fx_benchmark(d)
  ont <- fx_ontology()

  live <- if ("version_deprecated" %in% names(ont))
    !nzchar(ont$version_deprecated) else rep(TRUE, nrow(ont))
  live_ids <- unique(ont$variant_id[live])
  absent_ids <- setdiff(live_ids, unique(res$gold_variant_id))
  skip_if(length(absent_ids) == 0, "no live variant is absent from the mini set")

  g_with <- fx_coverage_gaps(res, include_absent = TRUE)
  g_wo   <- fx_coverage_gaps(res, include_absent = FALSE)

  # the toggle adds exactly the absent live variants, all as support-0 needs-cases
  expect_identical(names(g_with), names(g_wo))
  expect_equal(nrow(g_with) - nrow(g_wo), length(absent_ids))
  absent_rows <- g_with[g_with$support == 0L, ]
  expect_setequal(absent_rows$gold_variant_id, absent_ids)
  expect_true(all(absent_rows$bucket == "needs-cases"))
  expect_true(all(is.na(absent_rows$acc_type)))
  expect_false(any(duplicated(g_with$gold_variant_id)))

  # a NULL ontology degrades gracefully: no absent rows, no error
  g_null <- fx_coverage_gaps(res, ontology = NULL)
  expect_false(any(g_null$support == 0L))
})

test_that("comparing a run against itself yields zero deltas", {
  d   <- fx_benchmark_data("mini")
  res <- fx_benchmark(d[1:24, ])
  cmp <- fx_benchmark_compare(res, res)
  expect_true(all(abs(cmp$overall$delta) < 1e-9))
  expect_true(all(abs(cmp$by_data_type$delta) < 1e-9, na.rm = TRUE))
})
