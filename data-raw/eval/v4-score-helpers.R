## data-raw/eval/v4-score-helpers.R
## Shared prediction + feasibility-scoring helpers for the V4 eval runs
## (Sherlock, GitTables). Assumes the package is load_all()'d and that
## ontology-old-to-v4-map.csv sits in data-raw/eval/.

.omap <- read.csv("data-raw/eval/ontology-old-to-v4-map.csv",
                  stringsAsFactors = FALSE, check.names = FALSE)
.okey <- with(.omap, paste(old_type, old_subtype, old_class, sep = "/"))

## old (type/subtype/class) -> V4 (type,class,subclass)
translate_v4 <- function(ot, os, oc) {
  i <- match(paste(ot, os, oc, sep = "/"), .okey)
  if (is.na(i)) return(c(NA, NA, NA))
  c(.omap$v4_type[i], .omap$v4_class[i], .omap$v4_subclass[i])
}

## Coarse SHAPE backstop when no mask/lookup detector fires. Deliberately
## conservative: claim only what the values safely support.
##  * all-numeric, strictly within (0,1) -> number/portion/probability
##  * all-numeric otherwise             -> number/quantity   (safe floor)
##  * low-cardinality strings           -> categorical/mutually_exclusive
##  * else                              -> text/text
shape_floor <- function(v) {
  v <- v[!is.na(v) & nzchar(trimws(v))]
  if (!length(v)) return(c(NA, NA, NA))
  nums <- suppressWarnings(as.numeric(gsub("[,$ ]", "", v)))
  if (!any(is.na(nums))) {
    rng <- range(nums)
    if (rng[1] >= 0 && rng[2] <= 1 && any(nums > 0 & nums < 1))
      return(c("number", "portion", "probability"))
    return(c("number", "quantity", NA))                 # safe class-level floor
  }
  u <- length(unique(tolower(trimws(v))))
  if (u <= max(2, 0.3 * length(v)) && u <= 50)
    return(c("categorical", "mutually_exclusive", NA))
  c("text", "text", NA)
}

## Predict a V4 coordinate for one column, plus diagnostics.
predict_v4 <- function(values, name = NULL) {
  g  <- guess_column(values, name = name, floor = 0.25)
  vg <- g$value
  cand <- vg$candidates
  fired <- if (!is.null(cand) && nrow(cand))
    paste0(utils::head(cand$data_type, 5), ":",
           sprintf("%.2f", utils::head(cand$pass_rate, 5)), collapse = "; ") else "none"
  unit <- NA_character_
  if (!is.na(g$guess)) {
    o <- g$ontology
    tri <- translate_v4(o[["data_type"]], o[["data_subtype"]], o[["data_class"]])
    basis <- paste0(g$source, ":", g$guess)
    if (g$guess %in% c("currency_symbol", "currency_code_symbol", "currency_code"))
      unit <- "currency"
  } else {
    tri <- shape_floor(values)
    basis <- paste0("shape:", paste(stats::na.omit(tri), collapse = "/"))
  }
  list(type = tri[1], class = tri[2], subclass = tri[3], unit = unit,
       basis = basis, winner = if (is.na(g$guess)) "-" else g$guess, fired = fired)
}

## first n values, truncated, for a reviewable glimpse
glimpse_of <- function(v, n = 8, w = 22) {
  v <- v[!is.na(v) & nzchar(trimws(v))]
  s <- utils::head(as.character(v), n)
  s <- ifelse(nchar(s) > w, paste0(substr(s, 1, w - 1), "…"), s)
  paste(s, collapse = " | ")
}

## Score a set of columns against a V4 feasibility crosswalk keyed by `key_col`.
score_columns_v4 <- function(columns, labels, crosswalk,
                             key_col = "sherlock_type", names = NULL) {
  rows <- lapply(seq_along(columns), function(i) {
    cw <- crosswalk[match(labels[i], crosswalk[[key_col]]), ]
    if (is.na(cw[[key_col]])) return(NULL)
    p <- predict_v4(columns[[i]], name = if (!is.null(names)) names[i] else NULL)
    s <- feasibility_score(
      pred  = c(p$type, p$class, p$subclass),
      ideal = c(cw$v4_type, cw$v4_class, cw$v4_subclass),
      feasible_depth = cw$feasible_depth,
      pred_unit = p$unit, ideal_unit = cw$unit)
    data.frame(
      label = labels[i],
      glimpse = glimpse_of(columns[[i]]),
      n = length(columns[[i]]),
      pred = paste(stats::na.omit(c(p$type, p$class, p$subclass)), collapse = "/"),
      pred_basis = p$basis,
      fired = p$fired,
      ideal = paste(stats::na.omit(c(cw$v4_type, cw$v4_class, cw$v4_subclass)), collapse = "/"),
      feasible_depth = cw$feasible_depth,
      score = s$score, unit_recovered = s$unit_recovered,
      stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

report_scores <- function(res, title) {
  cat("\n===", title, "===\n")
  cat(sprintf("n=%d  |  score 0=%d  1=%d  2=%d  |  mean=%.2f\n",
      nrow(res), sum(res$score==0), sum(res$score==1), sum(res$score==2),
      mean(res$score)))
  ur <- res$unit_recovered[!is.na(res$unit_recovered)]
  if (length(ur)) cat(sprintf("unit recovered: %d / %d unit-bearing\n", sum(ur), length(ur)))
  cat("\nby score:\n")
  for (sc in 0:2) {
    sub <- res[res$score==sc, ]
    cat(sprintf("  [%d] %d cols: %s\n", sc, nrow(sub),
        paste(utils::head(sort(unique(sub$label)), 12), collapse=", ")))
  }
}
