## data-raw/eval/run-sherlock-v4-score.R
## -------------------------------------------------------------------------
## Feasibility scoring of formex against the Sherlock 78-type benchmark, in V4
## coordinates. Pipeline per column:
##   1. PREDICT   guess_column() -> old-schema ontology coords
##   2. TRANSLATE old -> V4 via ontology-old-to-v4-map.csv; if no detector fired,
##      a coarse SHAPE backstop emits the honest floor (number/quantity,
##      categorical/mutually_exclusive, or text/text).
##   3. SCORE     feasibility_score() vs sherlock-crosswalk-v4.csv:
##      path 0/1/2 against the feasible ceiling + a unit_recovered flag.
##
## Runs on the Sherlock parquet if present (see run-sherlock-eval.R for the
## download); otherwise falls back to a small SYNTHETIC demo so the harness is
## runnable and self-checking without the 500MB pull.
##   Rscript data-raw/eval/run-sherlock-v4-score.R
## -------------------------------------------------------------------------

DIR <- "data-raw/eval"
suppressMessages(pkgload::load_all(".", quiet = TRUE))
xwalk <- read.csv(file.path(DIR, "sherlock-crosswalk-v4.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)
omap  <- read.csv(file.path(DIR, "ontology-old-to-v4-map.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)
okey  <- with(omap, paste(old_type, old_subtype, old_class, sep = "/"))

## old (type/subtype/class) -> V4 (type,class,subclass); NA triple if unmapped
translate_v4 <- function(ot, os, oc) {
  i <- match(paste(ot, os, oc, sep = "/"), okey)
  if (is.na(i)) return(c(NA, NA, NA))
  c(omap$v4_type[i], omap$v4_class[i], omap$v4_subclass[i])
}

## coarse shape backstop when no mask/lookup detector fires
shape_floor <- function(v) {
  v <- v[!is.na(v) & nzchar(trimws(v))]
  if (!length(v)) return(c(NA, NA, NA))
  num <- suppressWarnings(!any(is.na(as.numeric(gsub("[, ]", "", v)))))
  if (num) return(c("number", "quantity", NA))          # class-level floor
  u <- length(unique(v))
  if (u <= max(2, 0.5 * length(v))) return(c("categorical", "mutually_exclusive", NA))
  c("text", "text", NA)                                  # generic free text
}

## predict V4 coords + unit for one column
predict_v4 <- function(values, name = NULL) {
  g <- guess_column(values, name = name)
  unit <- NA_character_
  if (!is.na(g$guess)) {
    o <- g$ontology
    tri <- translate_v4(o[["data_type"]], o[["data_subtype"]], o[["data_class"]])
    if (g$guess %in% c("currency_symbol", "currency_code_symbol", "currency_code"))
      unit <- "currency"
  } else {
    tri <- shape_floor(values)
  }
  list(type = tri[1], class = tri[2], subclass = tri[3], unit = unit)
}

## score a set of (values, sherlock_type[, name]) against the crosswalk
score_columns <- function(columns, types, names = NULL) {
  rows <- lapply(seq_along(columns), function(i) {
    cw <- xwalk[match(types[i], xwalk$sherlock_type), ]
    if (is.na(cw$sherlock_type)) return(NULL)
    p <- predict_v4(columns[[i]], name = if (!is.null(names)) names[i] else NULL)
    s <- feasibility_score(
      pred  = c(p$type, p$class, p$subclass),
      ideal = c(cw$v4_type, cw$v4_class, cw$v4_subclass),
      feasible_depth = cw$feasible_depth,
      pred_unit = p$unit, ideal_unit = cw$unit)
    data.frame(sherlock_type = types[i],
               pred = paste(na.omit(c(p$type, p$class, p$subclass)), collapse = "/"),
               ideal = paste(na.omit(c(cw$v4_type, cw$v4_class, cw$v4_subclass)), collapse = "/"),
               feasible_depth = cw$feasible_depth,
               score = s$score, unit_recovered = s$unit_recovered,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

report <- function(res, title) {
  cat("\n===", title, "===\n")
  print(res, row.names = FALSE)
  cat(sprintf("\nscore distribution: 0=%d  1=%d  2=%d  (n=%d)\n",
      sum(res$score==0), sum(res$score==1), sum(res$score==2), nrow(res)))
  ur <- res$unit_recovered[!is.na(res$unit_recovered)]
  if (length(ur)) cat(sprintf("unit recovered on %d of %d unit-bearing columns\n",
                              sum(ur), length(ur)))
}

## --- synthetic demo (always runnable) --------------------------------------
demo <- list(
  list(t="birth date", v=c("1987-02-06","2001-11-30","1999-12-31")),
  list(t="email",      v=c("a@b.com","c@d.org","e@f.net")),
  list(t="isbn",       v=c("978-3-16-148410-0","0-306-40615-2")),
  list(t="city",       v=c("Chicago","Boston","Seattle","Denver")),
  list(t="currency",   v=c("$14.25","$31.00","$9.75")),
  list(t="weight",     v=c("72.5","98.1","64.0","81.2")),
  list(t="rank",       v=c("1","2","3","4","5")),
  list(t="year",       v=c("1999","2001","2010","2019")),
  list(t="status",     v=c("active","inactive","active","pending")),
  list(t="symbol",     v=c("AAPL","MSFT","GOOG"))   # NULL target
)
res <- score_columns(lapply(demo, `[[`, "v"), vapply(demo, `[[`, "", "t"))
report(res, "SYNTHETIC feasibility demo (Sherlock types)")
message("\n(For the full 78-type run, point this script at the Sherlock parquet.)")
