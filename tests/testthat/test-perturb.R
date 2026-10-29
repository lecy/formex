# The stress-test grid: controlled perturbations of benchmark columns, re-scored
# to measure accuracy decay per dimension and level.

test_that("spelling substitution preserves character class", {
  set.seed(1)
  digits <- fx_perturb(c("12345", "67890"), "spelling", "medium", seed = 1)
  expect_true(all(grepl("^[0-9]+$", digits)))           # digit -> digit only
  alnum <- fx_perturb(c("AB12cd", "ZZ99yy"), "spelling", "medium", seed = 2)
  # letters stay letters, digits stay digits, positionwise
  for (k in seq_along(alnum)) {
    a <- strsplit(c("AB12cd", "ZZ99yy")[k], "")[[1]]
    b <- strsplit(alnum[k], "")[[1]]
    cls <- function(ch) ifelse(grepl("[0-9]", ch), "d",
                        ifelse(grepl("[a-z]", ch), "l", "u"))
    expect_equal(cls(a), cls(b))
  }
})

test_that("length resamples to the requested size", {
  x <- as.character(1:40)
  expect_equal(length(fx_perturb(x, "length", "n50",  seed = 1)), 50)
  expect_equal(length(fx_perturb(x, "length", "n100", seed = 1)), 100)
})

test_that("contamination mixes foil values but keeps length", {
  x <- rep("California", 20)
  foil <- as.character(1:9)
  y <- fx_perturb(x, "contamination", "medium", foil = foil, seed = 1)
  expect_equal(length(y), length(x))
  expect_true(any(y %in% foil))          # some foil mixed in
  expect_true(any(y == "California"))    # but not all replaced (25% < 50%)
})

test_that("scramble permutes positions but preserves the character multiset", {
  s <- "AB-12-CD"
  p <- fx_perturb(s, "scramble_alnum", "medium", seed = 3)
  expect_equal(sort(strsplit(s, "")[[1]]), sort(strsplit(p, "")[[1]]))
})

test_that("fx_stress_grid emits a clean baseline plus graded perturbations", {
  d   <- fx_benchmark_data("mini")
  sub <- d[d$data_type %in% c("temporal", "categorical"), ][1:12, ]
  g <- fx_stress_grid(sub, dimensions = c("spelling", "contamination"), seed = 1)
  expect_s3_class(g, "data.frame")
  expect_true(all(c("case_id", "dimension", "level", "applicable",
                    "type_correct", "headline", "outcome", "elapsed_sec") %in%
                  names(g)))
  expect_true("(clean)" %in% g$dimension)
  expect_setequal(setdiff(unique(g$dimension), "(clean)"),
                  c("spelling", "contamination"))
})

test_that("fx_stress_summary measures decay from the clean baseline", {
  d   <- fx_benchmark_data("mini")
  sub <- d[d$data_type %in% c("temporal", "categorical", "identifier"), ][1:18, ]
  g <- fx_stress_grid(sub, dimensions = c("contamination"),
                      contamination_sweep = TRUE, seed = 1)
  s <- fx_stress_summary(g)
  expect_true(all(c("by_level", "by_type", "clean") %in% names(s)))
  expect_true(all(c("dimension", "level", "acc_type", "delta_type") %in%
                  names(s$by_level)))

  cur <- fx_contamination_curve(g)
  expect_true(0 %in% cur$frac)                       # clean baseline present
  # heavier contamination should not score higher than the clean baseline
  acc0  <- cur$acc_type[cur$frac == 0]
  acc50 <- cur$acc_type[cur$frac == 0.5]
  expect_true(length(acc50) == 0 || acc50 <= acc0 + 1e-9)
})
