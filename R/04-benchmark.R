##############################
### Benchmark harness (guess_data_type over the frozen test library)
###############################
## Scores guess_data_type() against the banked test library at every ontology
## level (data_type -> semantic_family -> semantic_type -> format_style / unit),
## records runtime, and reports the SHAPE of errors (where a gold type lands when
## it is wrong; graceful truncation vs. a committed wrong branch). The substrate
## is the frozen benchmark built by data-raw/build_benchmark.R: a small "mini"
## set ships in inst/extdata/ (tests / CI / offline), and a "full" set is fetched
## from a remote host and cached. One row per column, carrying the capped unique
## values + counts and the gold label at each level (gold_style / gold_unit are
## best-effort, NA where the ontology does not pin a determinate value).

## The ordered ontology levels and their default partial-credit weights. A level
## is correct only if every ancestor is also correct (hierarchical credit); the
## headline renormalizes over the levels whose gold is defined for a case.
.FX_LEVELS <- c("data_type", "semantic_family", "semantic_type",
                "format_style", "unit")

#' @keywords internal
#' @noRd
.fx_level_weights <- function() {
  c(data_type = 0.40, semantic_family = 0.20, semantic_type = 0.20,
    format_style = 0.10, unit = 0.10)
}

## read a $route field defensively (the unit axis is dd_unit or unit_type)
#' @keywords internal
#' @noRd
.fx_route_get <- function(route, field) {
  if (identical(field, "unit")) {
    v <- route[["unit_type"]]
    if (is.null(v)) v <- route[["dd_unit"]]
  } else {
    v <- route[[field]]
  }
  if (is.null(v) || length(v) != 1L) return(NA_character_)
  v <- as.character(v)
  if (!nzchar(v)) NA_character_ else v
}

## rebuild a column vector from the stored unique values + counts (capped)
#' @keywords internal
#' @noRd
.fx_rebuild <- function(values, counts = NULL, max_n = 300L) {
  values <- as.character(values)
  if (is.null(counts) || length(counts) != length(values))
    counts <- rep(1L, length(values))
  counts <- pmax(1L, as.integer(counts))
  x <- rep(values, counts)
  if (length(x) > max_n) x <- x[seq_len(max_n)]
  x
}

## Score one column: run + time guess_data_type(), compare predicted route to the
## gold levels under the hierarchical rule, and classify the outcome. `gold` is a
## named list/row with data_type, semantic_family, semantic_type, gold_style,
## gold_unit. Returns a one-row data frame. Shared with the stress grid (Part B).
#' @keywords internal
#' @noRd
.fx_score_case <- function(values, gold, router = "auto",
                           weights = .fx_level_weights()) {
  t0 <- proc.time()[["elapsed"]]
  g  <- tryCatch(guess_data_type(values, router = router),
                 error = function(e) NULL)
  elapsed <- proc.time()[["elapsed"]] - t0
  route <- if (is.null(g)) list() else g$route

  pred <- c(
    data_type       = .fx_route_get(route, "data_type"),
    semantic_family = .fx_route_get(route, "semantic_family"),
    semantic_type   = .fx_route_get(route, "semantic_type"),
    format_style    = .fx_route_get(route, "format_style"),
    unit            = .fx_route_get(route, "unit"))
  goldv <- c(
    data_type       = as.character(gold[["data_type"]]      %||% NA_character_),
    semantic_family = as.character(gold[["semantic_family"]] %||% NA_character_),
    semantic_type   = as.character(gold[["semantic_type"]]   %||% NA_character_),
    format_style    = as.character(gold[["gold_style"]]      %||% NA_character_),
    unit            = as.character(gold[["gold_unit"]]       %||% NA_character_))

  ## hierarchical correctness; NA where a level's gold is not defined (not scored)
  correct <- stats::setNames(rep(NA, length(.FX_LEVELS)), .FX_LEVELS)
  dt_ok  <- !is.na(goldv["data_type"])       && identical(pred["data_type"],       goldv["data_type"])
  fam_ok <- dt_ok  && !is.na(goldv["semantic_family"]) && identical(pred["semantic_family"], goldv["semantic_family"])
  st_ok  <- fam_ok && !is.na(goldv["semantic_type"])   && identical(pred["semantic_type"],   goldv["semantic_type"])
  correct["data_type"]       <- dt_ok
  correct["semantic_family"] <- if (is.na(goldv["semantic_family"])) NA else fam_ok
  correct["semantic_type"]   <- if (is.na(goldv["semantic_type"]))   NA else st_ok
  correct["format_style"]    <- if (is.na(goldv["format_style"]))    NA else
                                   (st_ok && identical(pred["format_style"], goldv["format_style"]))
  correct["unit"]            <- if (is.na(goldv["unit"]))            NA else
                                   (st_ok && identical(pred["unit"], goldv["unit"]))

  scored  <- !is.na(correct)
  w       <- weights[.FX_LEVELS][scored]
  headline <- if (length(w) && sum(w) > 0)
    sum(w * as.numeric(correct[scored])) / sum(w) else NA_real_

  ## outcome shape: hit (type matched) / graceful (correct prefix, stopped short)
  ## / misroute (committed to a wrong branch)
  pred_st_na <- is.na(pred["semantic_type"])
  outcome <- if (isTRUE(st_ok)) "hit"
             else if (isTRUE(dt_ok) && pred_st_na) "graceful"
             else "misroute"

  data.frame(
    pred_data_type       = unname(pred["data_type"]),
    pred_semantic_family = unname(pred["semantic_family"]),
    pred_semantic_type   = unname(pred["semantic_type"]),
    pred_format_style    = unname(pred["format_style"]),
    pred_unit            = unname(pred["unit"]),
    dt_correct    = unname(correct["data_type"]),
    family_correct= unname(correct["semantic_family"]),
    type_correct  = unname(correct["semantic_type"]),
    style_correct = unname(correct["format_style"]),
    unit_correct  = unname(correct["unit"]),
    headline      = headline,
    outcome       = outcome,
    depth         = suppressWarnings(as.integer(route[["depth"]] %||% NA)),
    confidence    = suppressWarnings(as.numeric(route[["confidence"]] %||% NA)),
    elapsed_sec   = elapsed,
    stringsAsFactors = FALSE, row.names = NULL)
}

#' Locate and load the frozen benchmark dataset
#'
#' Returns the frozen evaluation set used by [fx_benchmark()] and
#' [fx_stress_grid()]. Both the small `"mini"` set and the full set ship with the
#' package, so this works offline with no setup. `refresh = TRUE` instead
#' downloads a (possibly newer / larger) full set from a remote host and caches
#' it under [tools::R_user_dir()]; the URL comes from
#' `getOption("formex.benchmark_url")` or the `FORMEX_BENCHMARK_URL` environment
#' variable (default: the package's GitHub release asset). If a requested remote
#' fetch fails, it falls back to the packaged copy with a message.
#'
#' @param which `"mini"` (fast, for tests / examples) or `"full"`.
#' @param tier Keep all rows (`"all"`), only the clean banks (`"clean"`), or only
#'   the vetted Sherlock slice (`"sherlock"`).
#' @param refresh If `TRUE`, (re-)download the full set from the remote host and
#'   cache it, instead of using the packaged copy.
#' @return A data frame, one row per banked column (see the file header for the
#'   schema), with `benchmark_version` and `built_on` attributes.
#' @seealso [fx_benchmark()], [fx_stress_grid()]
#' @export
fx_benchmark_data <- function(which = c("mini", "full"),
                              tier = c("all", "clean", "sherlock"),
                              refresh = FALSE) {
  which <- match.arg(which); tier <- match.arg(tier)
  load_pkg <- function(name) {
    p <- system.file("extdata", name, package = "formex")
    if (!nzchar(p)) stop("packaged ", name, " not found", call. = FALSE)
    readRDS(p)
  }
  fetch_full <- function() {
    url <- getOption("formex.benchmark_url", Sys.getenv("FORMEX_BENCHMARK_URL",
      "https://github.com/lecy/formex/releases/download/benchmark-1.0.0/benchmark_full.rds"))
    cache <- tools::R_user_dir("formex", "cache")
    dir.create(cache, showWarnings = FALSE, recursive = TRUE)
    dest <- file.path(cache, "benchmark_full.rds")
    ok <- tryCatch({
      utils::download.file(url, dest, mode = "wb", quiet = TRUE); TRUE
    }, error = function(e) FALSE)
    if (!ok) {
      message("fx_benchmark_data(): could not fetch the full set from ", url,
              " -- using the packaged copy instead.")
      return(load_pkg("benchmark_full.rds"))
    }
    readRDS(dest)
  }
  df <- if (which == "mini") load_pkg("benchmark_mini.rds")
        else if (refresh)    fetch_full()
        else                 load_pkg("benchmark_full.rds")
  if (tier != "all") df <- df[df$tier == tier, , drop = FALSE]
  rownames(df) <- NULL
  df
}

#' Benchmark guess_data_type() over the frozen test library
#'
#' Runs [guess_data_type()] on every column in `data`, times each call, and
#' scores the predicted `$route` against the gold label at every ontology level
#' under hierarchical partial credit (a level counts only if all its ancestors
#' match). `gold_style` / `gold_unit` are scored only where defined.
#'
#' @param data A benchmark data frame from [fx_benchmark_data()].
#' @param router Router strategy passed to [guess_data_type()]
#'   (`"auto"`, `"learned"`, `"signature"`).
#' @param weights Named partial-credit weights over the ontology levels.
#' @param max_n Cap on the reconstructed column length (speed guard).
#' @param progress If `TRUE`, print a progress dot every 50 cases.
#' @return A data frame, one row per case: the gold and predicted levels, the
#'   per-level `*_correct` flags (`NA` where not scored), the `headline` score,
#'   the `outcome` shape, `depth`, `confidence`, and `elapsed_sec`.
#' @seealso [fx_benchmark_summary()], [fx_benchmark_confusion()],
#'   [fx_coverage_gaps()], [fx_benchmark_compare()]
#' @export
fx_benchmark <- function(data = fx_benchmark_data(), router = "auto",
                         weights = .fx_level_weights(), max_n = 300L,
                         progress = FALSE) {
  stopifnot(is.data.frame(data), nrow(data) > 0)
  n <- nrow(data)
  rows <- vector("list", n)
  for (i in seq_len(n)) {
    vals  <- .fx_rebuild(data$values[[i]],
                         if (!is.null(data$counts)) data$counts[[i]] else NULL, max_n)
    score <- .fx_score_case(vals, data[i, ], router = router, weights = weights)
    rows[[i]] <- cbind(
      data.frame(case_id = data$case_id[i], tier = data$tier[i],
                 corpus = data$corpus[i], difficulty = data$difficulty[i],
                 gold_data_type = data$data_type[i],
                 gold_semantic_family = data$semantic_family[i],
                 gold_semantic_type = data$semantic_type[i],
                 gold_variant_id = data$variant_id[i],
                 gold_style = data$gold_style[i], gold_unit = data$gold_unit[i],
                 n_values = length(vals), stringsAsFactors = FALSE),
      score)
    if (progress && i %% 50L == 0L) cat(".")
  }
  if (progress) cat("\n")
  out <- do.call(rbind, rows)
  attr(out, "router") <- router
  attr(out, "benchmark_version") <- attr(data, "benchmark_version")
  out
}

## accuracy over a logical column, ignoring NA (unscored) entries
#' @keywords internal
#' @noRd
.fx_acc <- function(x) { x <- x[!is.na(x)]; if (length(x)) mean(x) else NA_real_ }

#' Summarize a benchmark run
#'
#' @param res Output of [fx_benchmark()].
#' @param by_tier If `TRUE`, also break the per-level accuracy out by `tier`.
#' @return A list with `overall` (per-level accuracy, mean headline, prediction
#'   coverage, and the hit/graceful/misroute mix), `by_data_type` (per gold
#'   data_type: support, type accuracy, headline), `runtime` (total / mean /
#'   median / p95 seconds per case), and, when `by_tier`, a `by_tier` table.
#' @seealso [fx_benchmark()]
#' @export
fx_benchmark_summary <- function(res, by_tier = TRUE) {
  lvl <- function(d) data.frame(
    n = nrow(d),
    acc_data_type = .fx_acc(d$dt_correct),
    acc_family    = .fx_acc(d$family_correct),
    acc_type      = .fx_acc(d$type_correct),
    acc_style     = .fx_acc(d$style_correct),
    acc_unit      = .fx_acc(d$unit_correct),
    headline      = mean(d$headline, na.rm = TRUE),
    coverage      = mean(!is.na(d$pred_data_type)),
    hit      = mean(d$outcome == "hit"),
    graceful = mean(d$outcome == "graceful"),
    misroute = mean(d$outcome == "misroute"),
    stringsAsFactors = FALSE)

  overall <- lvl(res)
  bydt <- do.call(rbind, lapply(split(res, res$gold_data_type), function(d)
    data.frame(gold_data_type = d$gold_data_type[1], support = nrow(d),
               acc_data_type = .fx_acc(d$dt_correct),
               acc_type = .fx_acc(d$type_correct),
               headline = mean(d$headline, na.rm = TRUE),
               stringsAsFactors = FALSE)))
  bydt <- bydt[order(-bydt$support), , drop = FALSE]; rownames(bydt) <- NULL

  e <- res$elapsed_sec
  runtime <- data.frame(total_sec = sum(e), mean_sec = mean(e),
                        median_sec = stats::median(e),
                        p95_sec = unname(stats::quantile(e, 0.95)),
                        stringsAsFactors = FALSE)

  out <- list(overall = overall, by_data_type = bydt, runtime = runtime)
  if (by_tier && length(unique(res$tier)) > 1L) {
    bt <- do.call(rbind, lapply(split(res, res$tier), function(d)
      cbind(data.frame(tier = d$tier[1], stringsAsFactors = FALSE), lvl(d))))
    rownames(bt) <- NULL
    out$by_tier <- bt
  }
  out
}

#' Confusion structure: what shape does "wrong" take?
#'
#' @param res Output of [fx_benchmark()].
#' @param level Ontology level to tabulate (default `"data_type"`).
#' @return A list with `matrix` (gold x predicted counts at `level`),
#'   `wrong_shape` (for each gold value, the distribution of the *wrong*
#'   predicted values, as proportions), and `outcome` (the per-gold-data_type
#'   hit / graceful / misroute mix, so graceful truncation is separated from a
#'   committed wrong branch).
#' @seealso [fx_benchmark()]
#' @export
fx_benchmark_confusion <- function(res, level = c("data_type", "semantic_family",
                                                   "semantic_type")) {
  level <- match.arg(level)
  gcol <- paste0("gold_",
                 c(data_type = "data_type", semantic_family = "semantic_family",
                   semantic_type = "semantic_type")[level])
  pcol <- paste0("pred_",
                 c(data_type = "data_type", semantic_family = "semantic_family",
                   semantic_type = "semantic_type")[level])
  gold <- res[[gcol]]; pred <- res[[pcol]]
  pred[is.na(pred)] <- "<none>"
  cm <- table(gold = gold, predicted = pred)

  wrong_shape <- lapply(sort(unique(gold)), function(g) {
    w <- pred[gold == g & pred != g]
    if (!length(w)) return(NULL)
    p <- sort(prop.table(table(w)), decreasing = TRUE)
    data.frame(gold = g, predicted = names(p), prop = as.numeric(p),
               stringsAsFactors = FALSE)
  })
  wrong_shape <- do.call(rbind, Filter(Negate(is.null), wrong_shape))

  outcome <- do.call(rbind, lapply(split(res, res$gold_data_type), function(d)
    data.frame(gold_data_type = d$gold_data_type[1], support = nrow(d),
               hit = mean(d$outcome == "hit"),
               graceful = mean(d$outcome == "graceful"),
               misroute = mean(d$outcome == "misroute"),
               stringsAsFactors = FALSE)))
  rownames(outcome) <- NULL
  list(matrix = cm, wrong_shape = wrong_shape, outcome = outcome)
}

#' Coverage gaps: types the benchmark types poorly or barely covers
#'
#' The machine-readable companion to the coverage notes in
#' `DEVELOPMENT-STATUS.md`: the variants with the lowest type accuracy or the
#' thinnest support, so attention goes where it moves the needle.
#'
#' @param res Output of [fx_benchmark()].
#' @param min_support Flag variants with fewer than this many cases.
#' @param max_accuracy Flag variants whose type accuracy is at or below this.
#' @return A data frame per gold variant: `support`, `acc_type`, `acc_headline`,
#'   the dominant wrong prediction (`top_wrong`), and `flag`
#'   (`"low-support"` / `"low-accuracy"` / `"ok"`), ordered worst first.
#' @seealso [fx_benchmark()], [fx_benchmark_confusion()]
#' @export
fx_coverage_gaps <- function(res, min_support = 3L, max_accuracy = 0.5) {
  do.call(rbind, lapply(split(res, res$gold_variant_id), function(d) {
    acc <- .fx_acc(d$type_correct)
    wrong <- d$pred_semantic_type[!is.na(d$type_correct) & !d$type_correct]
    wrong <- wrong[!is.na(wrong)]          # all-NA wrongs (truncated) -> no top
    top <- if (length(wrong)) names(sort(table(wrong), decreasing = TRUE))[1] else NA_character_
    flag <- if (nrow(d) < min_support) "low-support"
            else if (!is.na(acc) && acc <= max_accuracy) "low-accuracy" else "ok"
    data.frame(gold_variant_id = d$gold_variant_id[1],
               gold_data_type = d$gold_data_type[1],
               gold_semantic_type = d$gold_semantic_type[1],
               support = nrow(d), acc_type = acc,
               acc_headline = mean(d$headline, na.rm = TRUE),
               top_wrong = top, flag = flag, stringsAsFactors = FALSE)
  })) -> g
  g <- g[order(g$flag == "ok", g$acc_type, g$support), , drop = FALSE]
  rownames(g) <- NULL
  g
}

#' Compare two benchmark runs (track progress over time)
#'
#' @param old,new Outputs of [fx_benchmark()] (e.g. before/after a change).
#' @return A list with `overall` (per-level accuracy and headline deltas,
#'   new minus old) and `by_data_type` (per gold data_type, the type-accuracy
#'   delta), with regressions (negative deltas) sorted first.
#' @seealso [fx_benchmark()], [fx_benchmark_summary()]
#' @export
fx_benchmark_compare <- function(old, new) {
  so <- fx_benchmark_summary(old, by_tier = FALSE)$overall
  sn <- fx_benchmark_summary(new, by_tier = FALSE)$overall
  cols <- c("acc_data_type", "acc_family", "acc_type", "acc_style",
            "acc_unit", "headline")
  overall <- data.frame(metric = cols,
                        old = unlist(so[cols]), new = unlist(sn[cols]),
                        delta = unlist(sn[cols]) - unlist(so[cols]),
                        stringsAsFactors = FALSE, row.names = NULL)

  acc_by <- function(res) vapply(split(res, res$gold_data_type),
                                 function(d) .fx_acc(d$type_correct), numeric(1))
  ao <- acc_by(old); an <- acc_by(new)
  dts <- sort(union(names(ao), names(an)))
  bydt <- data.frame(gold_data_type = dts,
                     old = unname(ao[dts]), new = unname(an[dts]),
                     delta = unname(an[dts]) - unname(ao[dts]),
                     stringsAsFactors = FALSE)
  bydt <- bydt[order(bydt$delta), , drop = FALSE]; rownames(bydt) <- NULL
  list(overall = overall, by_data_type = bydt)
}
