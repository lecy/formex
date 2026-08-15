# Feature extractor (fx_extract_features): shape, determinism, edge cases,
# block gating, and frequency-weighted equivalence. Ported from the dev
# characterization suite after integration into the package (§6).

probe <- c(sprintf("%02d-%07d", 10:60, 1234567L), "Quercus alba", "12.50", "a@b.com")

test_that("default blocks return exactly 477 numeric/NA columns", {
  f <- fx_extract_features(probe, col_name = "probe_id")
  expect_equal(ncol(f), 477)          # 471 + 6 gazetteer lex cols (first/last/city)
  expect_true(all(vapply(f, is.numeric, logical(1))))
})

test_that("extraction is deterministic (RNG is seeded + non-invasive)", {
  x <- paste0("v", sprintf("%03d", 1:100), c("a","bb","ccc","d"))
  expect_equal(fx_extract_features(x, max_unique = 50),
               fx_extract_features(x, max_unique = 50))
  # and it must not disturb the caller's global RNG stream
  set.seed(42); a <- runif(1); invisible(fx_extract_features(x, max_unique = 20))
  b <- runif(1); set.seed(42); expect_equal(c(a, b), c(runif(1), runif(1)))
})

test_that("edge cases return without error", {
  for (x in list(character(0), c(NA, NA), c("", ""), rep("x", 5), "one",
                 factor(c("a","b","a")), as.Date("2020-01-01") + 0:3,
                 c(TRUE, FALSE, NA), c("café","naïve","Ω")))
    expect_silent(suppressWarnings(fx_extract_features(x)))
})

test_that("blocks= returns a strict subset; blocks_for_features includes core", {
  full <- names(fx_extract_features(probe, col_name = "p"))
  sub  <- names(fx_extract_features(probe, col_name = "p", blocks = c("core","mask")))
  expect_true(all(sub %in% full)); expect_lt(length(sub), length(full))
  bf <- fx_blocks_for_features(c("mask_top_share","rx_email"))
  expect_true("core" %in% bf)
})

test_that("proportion-based features are invariant to uniform replication", {
  x <- c(rep("Quercus", 4), rep("Acer rubrum", 2), "Pinus", "Betula")
  a <- fx_extract_features(x); b <- fx_extract_features(rep(x, 3))
  for (k in c("top1_share","entropy_norm","mask_top_share","pct_chr_alpha",
              "len_mean","pct_single_tok"))
    expect_equal(a[[k]], b[[k]], tolerance = 1e-9, info = k)
})
