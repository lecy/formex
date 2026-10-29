##############################
### Stress-test grid (controlled perturbations of the benchmark columns)
###############################
## An experimental design on top of fx_benchmark(): each banked column is
## perturbed along one DIMENSION at a graded LEVEL (clean / low / medium -- the
## medium level is calibrated to stress, not obliterate, the signal), then
## re-scored with .fx_score_case(). Reading the accuracy decay per dimension x
## level x data_type shows where detection is brittle. Dimensions:
##
##   spelling      class-preserving character substitution (digit<->digit,
##                 letter<->letter, case-class kept); stricter than AutoType S1
##   length        resample the column to N in {50,100,300} (subset: needs signal)
##   contamination mix in foil values from a different data_type (0 / 10% / 25%)
##   whitespace    stray leading/trailing/interior padding
##   case          random case folding (stresses the state/color/country lexicons)
##   missingness   inject sentinels ("", "NA", "N/A", "-", "null")
##   static        inject stray punctuation mid-value
##   scramble_punct  permute punctuation positions (reuses mutate_SP)
##   scramble_alnum  permute alphanumeric positions (new)
##
## Reuses the AutoType mutation module (R/00-autotype-functions.R). The bank's
## per-case mutation contract (order_is_signal) marks cases an ordered-format
## perturbation is EXPECTED to break, so those are not misread as regressions.

## ---- class-preserving substitution ----------------------------------------
## Replace eligible characters within their own class: digit->digit,
## lowercase->lowercase, uppercase->uppercase. `n` fixes an exact count of
## substitutions per string; otherwise each eligible char mutates with prob `p`.
#' @keywords internal
#' @noRd
.mutate_classwise <- function(s, p = 0.3, n = NULL) {
  chars <- strsplit(s, "")[[1]]
  if (!length(chars)) return(s)
  cls <- ifelse(grepl("[0-9]", chars), "d",
         ifelse(grepl("[a-z]", chars), "l",
         ifelse(grepl("[A-Z]", chars), "u", NA)))
  elig <- which(!is.na(cls))
  if (!length(elig)) return(s)
  hit <- if (!is.null(n)) elig[seq_len(min(n, length(elig)))]
         else elig[runif(length(elig)) < p]
  pool <- list(d = as.character(0:9), l = letters, u = LETTERS)
  for (i in hit) chars[i] <- sample(pool[[cls[i]]], 1L)
  paste(chars, collapse = "")
}

## permute the positions of alphanumeric characters, punctuation held fixed
#' @keywords internal
#' @noRd
.scramble_alnum <- function(s, p = 1.0) {
  chars <- strsplit(s, "")[[1]]
  is_an <- grepl("^[A-Za-z0-9]$", chars)
  idx <- which(is_an)
  if (length(idx) < 2L) return(s)
  move <- idx[runif(length(idx)) < p]
  if (length(move) < 2L) return(s)
  chars[move] <- chars[sample(move)]
  paste(chars, collapse = "")
}

## apply a per-string mutator to a fraction `frac` of a vector's elements
#' @keywords internal
#' @noRd
.apply_frac <- function(x, frac, fn) {
  n <- length(x); k <- round(frac * n)
  if (k < 1L) return(x)
  idx <- sample(n, min(k, n))
  x[idx] <- vapply(x[idx], fn, character(1))
  x
}

.FX_SENTINELS <- c("", "NA", "N/A", "-", "null")
.FX_PUNCT     <- strsplit("!@#$%^&*._-/|", "")[[1]]

## the dimension x level parameter grid (levels beyond the shared clean baseline)
#' @keywords internal
#' @noRd
.fx_perturb_levels <- function() {
  list(
    spelling      = c("low", "medium"),
    length        = c("n50", "n100", "n300"),
    contamination = c("low", "medium"),
    whitespace    = c("low", "medium"),
    case          = c("low", "medium"),
    missingness   = c("low", "medium"),
    static        = c("low", "medium"),
    scramble_punct = c("low", "medium"),
    scramble_alnum = c("low", "medium"))
}

#' Perturb a column along one stress dimension
#'
#' @param values Character vector (a reconstructed column).
#' @param dimension One of the names in [fx_stress_grid()]'s default set.
#' @param level The graded level for that dimension (e.g. `"low"`, `"medium"`,
#'   or `"n50"`/`"n100"`/`"n300"` for `length`).
#' @param foil For `contamination`, a character vector of values drawn from a
#'   different data type to mix in.
#' @param seed Optional integer seed for reproducibility.
#' @return A perturbed character vector.
#' @seealso [fx_stress_grid()]
#' @export
fx_perturb <- function(values, dimension, level, foil = NULL, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.character(values)
  switch(dimension,
    spelling = {
      if (level == "low")  .apply_frac(x, 1.0, function(s) .mutate_classwise(s, n = 1L))
      else                  .apply_frac(x, 1.0, function(s) .mutate_classwise(s, p = 0.3))
    },
    length = {
      target <- as.integer(sub("^n", "", level))
      if (target <= length(x)) sample(x, target) else sample(x, target, replace = TRUE)
    },
    contamination = {
      frac <- if (level == "low") 0.10 else if (level == "medium") 0.25
              else suppressWarnings(as.numeric(level))     # sweep: a raw fraction
      if (is.na(frac) || is.null(foil) || !length(foil)) return(x)
      k <- round(frac * length(x)); if (k < 1L) return(x)
      idx <- sample(length(x), min(k, length(x)))
      x[idx] <- sample(foil, length(idx), replace = TRUE); x
    },
    whitespace = {
      frac <- if (level == "low") 0.10 else 0.25
      pad <- if (level == "low") function(s) paste0(" ", s, " ")
             else function(s) gsub(" ", "  ", paste0("  ", s, " "), fixed = TRUE)
      .apply_frac(x, frac, pad)
    },
    case = {
      if (level == "low")
        .apply_frac(x, 0.10, function(s) if (runif(1) < 0.5) toupper(s) else tolower(s))
      else vapply(x, function(s) {
        ch <- strsplit(s, "")[[1]]
        up <- runif(length(ch)) < 0.5
        ch[up] <- toupper(ch[up]); ch[!up] <- tolower(ch[!up])
        paste(ch, collapse = "")
      }, character(1))
    },
    missingness = {
      frac <- if (level == "low") 0.05 else 0.15
      .apply_frac(x, frac, function(s) sample(.FX_SENTINELS, 1L))
    },
    static = {
      frac <- if (level == "low") 0.05 else 0.15
      .apply_frac(x, frac, function(s) {
        if (!nchar(s)) return(s)
        pos <- sample(nchar(s) + 1L, 1L)
        paste0(substr(s, 1L, pos - 1L), sample(.FX_PUNCT, 1L),
               substr(s, pos, nchar(s)))
      })
    },
    scramble_punct = {
      p <- if (level == "low") 0.34 else 0.67
      vapply(x, function(s) mutate_SP(s, p), character(1))
    },
    scramble_alnum = {
      p <- if (level == "low") 0.34 else 0.67
      vapply(x, function(s) .scramble_alnum(s, p), character(1))
    },
    stop("unknown perturbation dimension: ", dimension)
  )
}

## pick a foil vector from a different data_type than `dt`
#' @keywords internal
#' @noRd
.fx_pick_foil <- function(data, dt, max_n = 50L) {
  others <- which(data$data_type != dt)
  if (!length(others)) return(NULL)
  j <- others[sample(length(others), 1L)]
  v <- .fx_rebuild(data$values[[j]],
                   if (!is.null(data$counts)) data$counts[[j]] else NULL, max_n)
  list(values = v, type = data$data_type[j])
}

#' Run the stress-test grid over the benchmark
#'
#' Perturbs every column in `data` along each requested dimension and level, then
#' re-scores with the benchmark's per-case scorer. A single shared `clean`
#' baseline per case is emitted (`dimension = "(clean)"`), so decay is measured
#' relative to it.
#'
#' @param data A benchmark data frame from [fx_benchmark_data()].
#' @param dimensions Which dimensions to run (default: all).
#' @param router Router passed to [guess_data_type()].
#' @param reps Repetitions per (case, dimension, level) for stochastic dimensions.
#' @param seed Base seed (per-cell seeds are derived from it, so runs reproduce).
#' @param max_n Cap on the reconstructed / resampled column length.
#' @param contamination_sweep If `TRUE`, also run contamination at 0.4 and 0.5 to
#'   locate the breaking point (see [fx_contamination_curve()]).
#' @param length_min_unique Minimum distinct values for the `length` dimension to
#'   apply to a case (others are recorded with `applicable = FALSE`).
#' @param progress If `TRUE`, print a progress dot every 200 runs.
#' @return A long data frame: `case_id, gold_data_type, gold_variant_id,
#'   dimension, level, rep, applicable, foil_type`, the per-level `*_correct`
#'   flags, `headline`, `outcome`, and `elapsed_sec`.
#' @seealso [fx_stress_summary()], [fx_contamination_curve()], [fx_perturb()]
#' @export
fx_stress_grid <- function(data = fx_benchmark_data(), dimensions = NULL,
                           router = "auto", reps = 1L, seed = 1L, max_n = 300L,
                           contamination_sweep = FALSE, length_min_unique = 10L,
                           progress = FALSE) {
  stopifnot(is.data.frame(data), nrow(data) > 0)
  all_levels <- .fx_perturb_levels()
  if (is.null(dimensions)) dimensions <- names(all_levels)
  dimensions <- intersect(dimensions, names(all_levels))
  if (contamination_sweep && "contamination" %in% dimensions)
    all_levels$contamination <- c(all_levels$contamination, "0.4", "0.5")

  out <- list(); kk <- 0L; ct <- 0L
  for (i in seq_len(nrow(data))) {
    base <- .fx_rebuild(data$values[[i]],
                        if (!is.null(data$counts)) data$counts[[i]] else NULL, max_n)
    gold <- data[i, ]
    mkrow <- function(dim, lvl, rep, applicable, foil_type, sc) {
      cbind(data.frame(case_id = data$case_id[i],
                       gold_data_type = data$data_type[i],
                       gold_variant_id = data$variant_id[i],
                       dimension = dim, level = lvl, rep = rep,
                       applicable = applicable, foil_type = foil_type,
                       stringsAsFactors = FALSE),
            sc[, c("dt_correct", "family_correct", "type_correct",
                   "style_correct", "unit_correct", "headline", "outcome",
                   "elapsed_sec")])
    }
    ## shared clean baseline
    kk <- kk + 1L
    out[[kk]] <- mkrow("(clean)", "clean", 1L, TRUE, NA_character_,
                       .fx_score_case(base, gold, router = router))
    for (dim in dimensions) {
      for (lvl in all_levels[[dim]]) {
        applicable <- TRUE
        if (dim == "length" && data$n_unique[i] < length_min_unique) applicable <- FALSE
        for (r in seq_len(reps)) {
          foil_type <- NA_character_; foil <- NULL
          if (dim == "contamination") {
            fp <- .fx_pick_foil(data, data$data_type[i], max_n)
            if (!is.null(fp)) { foil <- fp$values; foil_type <- fp$type }
          }
          if (!applicable) {
            sc <- .fx_score_case(base, gold, router = router)  # baseline stand-in
          } else {
            px <- fx_perturb(base, dim, lvl, foil = foil,
                             seed = seed + kk * 131L + r)
            sc <- .fx_score_case(px, gold, router = router)
          }
          kk <- kk + 1L
          out[[kk]] <- mkrow(dim, lvl, r, applicable, foil_type, sc)
          ct <- ct + 1L
          if (progress && ct %% 200L == 0L) cat(".")
        }
      }
    }
  }
  if (progress) cat("\n")
  res <- do.call(rbind, out); rownames(res) <- NULL
  attr(res, "router") <- router
  res
}

#' Summarize the stress grid: accuracy decay per dimension and level
#'
#' @param grid Output of [fx_stress_grid()].
#' @return A list with `by_level` (per dimension x level: type accuracy, headline,
#'   the hit/graceful/misroute mix, and `delta_type` / `delta_headline` versus the
#'   shared clean baseline) and `by_type` (per gold data_type x dimension x level:
#'   type accuracy and its delta from clean), both ordered to surface the largest
#'   drops first. Only `applicable` rows are counted.
#' @seealso [fx_stress_grid()]
#' @export
fx_stress_summary <- function(grid) {
  g <- grid[grid$applicable, , drop = FALSE]
  clean <- g[g$dimension == "(clean)", , drop = FALSE]
  base_type <- .fx_acc(clean$type_correct)
  base_head <- mean(clean$headline, na.rm = TRUE)

  by_level <- do.call(rbind, lapply(
    split(g, interaction(g$dimension, g$level, drop = TRUE)), function(d)
      data.frame(dimension = d$dimension[1], level = d$level[1], n = nrow(d),
                 acc_type = .fx_acc(d$type_correct),
                 headline = mean(d$headline, na.rm = TRUE),
                 hit = mean(d$outcome == "hit"),
                 graceful = mean(d$outcome == "graceful"),
                 misroute = mean(d$outcome == "misroute"),
                 stringsAsFactors = FALSE)))
  by_level$delta_type     <- by_level$acc_type - base_type
  by_level$delta_headline <- by_level$headline - base_head
  by_level <- by_level[order(by_level$dimension, by_level$delta_type), , drop = FALSE]
  rownames(by_level) <- NULL

  ## per gold data_type, accuracy delta from that type's clean baseline
  cbt <- tapply(clean$type_correct, clean$gold_data_type, .fx_acc)
  gg <- g[g$dimension != "(clean)", , drop = FALSE]
  by_type <- do.call(rbind, lapply(
    split(gg, interaction(gg$gold_data_type, gg$dimension, gg$level, drop = TRUE)),
    function(d) {
      bt <- cbt[[d$gold_data_type[1]]]
      acc <- .fx_acc(d$type_correct)
      data.frame(gold_data_type = d$gold_data_type[1], dimension = d$dimension[1],
                 level = d$level[1], n = nrow(d), acc_type = acc,
                 delta_type = acc - (bt %||% NA_real_), stringsAsFactors = FALSE)
    }))
  by_type <- by_type[order(by_type$delta_type), , drop = FALSE]
  rownames(by_type) <- NULL
  list(by_level = by_level, by_type = by_type,
       clean = data.frame(acc_type = base_type, headline = base_head))
}

#' Contamination breaking-point curve
#'
#' @param grid Output of [fx_stress_grid()] run with `contamination_sweep = TRUE`.
#' @return A data frame of mixing fraction vs. type accuracy (and headline),
#'   including the clean (0%) baseline, ordered by fraction -- the point where
#'   accuracy crosses ~0.5 is the empirical breaking point.
#' @seealso [fx_stress_grid()]
#' @export
fx_contamination_curve <- function(grid) {
  lvl_frac <- c(low = 0.10, medium = 0.25)
  g <- grid[grid$dimension %in% c("(clean)", "contamination"), , drop = FALSE]
  frac_of <- function(dim, lvl) {
    if (dim == "(clean)") return(0)
    if (!is.na(lvl_frac[lvl])) return(unname(lvl_frac[lvl]))
    suppressWarnings(as.numeric(lvl))
  }
  g$frac <- mapply(frac_of, g$dimension, g$level)
  do.call(rbind, lapply(split(g, g$frac), function(d)
    data.frame(frac = d$frac[1], n = nrow(d),
               acc_type = .fx_acc(d$type_correct),
               headline = mean(d$headline, na.rm = TRUE),
               stringsAsFactors = FALSE))) -> cur
  cur <- cur[order(cur$frac), , drop = FALSE]; rownames(cur) <- NULL
  cur
}
