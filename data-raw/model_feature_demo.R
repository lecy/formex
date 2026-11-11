## data-raw/model_feature_demo.R
## ---------------------------------------------------------------------------
## Worked one-vs-rest demonstrations for three data types (US state names,
## email addresses, EINs): impute per the spec, rank features by univariate
## discrimination (AUC), and fit a compact logistic regression on the top
## signals. Writes data-raw/model_feature_demo.rds for the documentation
## artifact. Illustrative, not a tuned model.
## ---------------------------------------------------------------------------
suppressMessages(pkgload::load_all(".", quiet = TRUE))
set.seed(514)

d    <- readRDS("data-raw/type_features_dataset.rds")
spec <- utils::read.csv("data-raw/type_features_imputation.csv", stringsAsFactors = FALSE)
meta_cols    <- c("corpus","source_label","vector_length","sample_values")
outcome_cols <- c("data_type","semantic_family","semantic_type",
                  "format_label","format_style","unit_type")
feat_cols <- setdiff(names(d), c(meta_cols, outcome_cols))

## --- imputation -------------------------------------------------------------
drop_f <- spec$feature[spec$na_rule == "drop"]
numf   <- spec$feature[spec$na_rule == "numeric_med"]
zerof  <- spec$feature[spec$na_rule == "zero"]
num_medians <- vapply(intersect(numf, names(d)),
                      function(f) stats::median(d[[f]], na.rm = TRUE), numeric(1))

impute <- function(df) {
  df <- df[, setdiff(names(df), drop_f), drop = FALSE]
  for (f in intersect(zerof, names(df))) df[[f]][is.na(df[[f]])] <- 0
  for (f in intersect(numf,  names(df))) {
    m <- num_medians[[f]]; if (is.na(m)) m <- 0
    df[[f]][is.na(df[[f]])] <- m
  }
  df
}

## --- bootstrap positive columns from a canonical formex vector --------------
env <- new.env()
for (f in list.files("data-raw/datatypes", pattern = "\\.R$", full.names = TRUE))
  sys.source(f, envir = env)

boot_features <- function(vec, B = 60, nmin = 12, nmax = 50) {
  vec <- as.character(vec); vec <- vec[!is.na(vec) & nzchar(trimws(vec))]
  do.call(rbind, lapply(seq_len(B), function(i) {
    k <- sample(nmin:nmax, 1)
    fx_extract_features(sample(vec, k, replace = TRUE), col_name = NULL)
  }))
}

## --- AUC (Mann-Whitney) + direction ----------------------------------------
auc1 <- function(score, y) {
  if (length(unique(score)) < 2) return(0.5)
  r <- rank(score); n1 <- sum(y); n0 <- sum(!y)
  (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

top_features <- function(pos_feat, neg_feat, k = 12) {
  all_nm <- intersect(names(pos_feat), names(neg_feat))
  P <- impute(pos_feat[, all_nm, drop = FALSE])
  N <- impute(neg_feat[, all_nm, drop = FALSE])
  fcols <- intersect(names(P), names(N))
  y <- c(rep(TRUE, nrow(P)), rep(FALSE, nrow(N)))
  X <- rbind(P[, fcols], N[, fcols])
  keep <- vapply(X, function(z) length(unique(z)) > 1, logical(1))
  X <- X[, keep, drop = FALSE]
  a <- vapply(X, auc1, numeric(1), y = y)
  res <- data.frame(
    feature   = names(a),
    auc       = round(a, 3),
    gini      = round(abs(2 * a - 1), 3),
    pos_mean  = round(vapply(X, function(z) mean(z[y]),  numeric(1)), 4),
    neg_mean  = round(vapply(X, function(z) mean(z[!y]), numeric(1)), 4),
    stringsAsFactors = FALSE
  )
  res <- res[order(-res$gini), ]; rownames(res) <- NULL
  list(top = head(res, k), X = X, y = y, auc = a)
}

## compact logistic fit on the top-k discriminating features
fit_logit <- function(tf, k = 6) {
  feats <- tf$top$feature[seq_len(min(k, nrow(tf$top)))]
  Xs <- scale(tf$X[, feats, drop = FALSE])
  df <- data.frame(y = as.integer(tf$y), Xs)
  m  <- suppressWarnings(stats::glm(y ~ ., df, family = binomial()))
  acc <- mean((predict(m, type = "response") > 0.5) == tf$y)
  list(features = feats, accuracy = round(acc, 3),
       coef = round(stats::coef(m)[-1], 2))
}

## --- build the three targets ------------------------------------------------
neg_sample <- function(exclude_labels, n = 500) {
  pool <- which(!(d$source_label %in% exclude_labels))
  d[sample(pool, min(n, length(pool))), feat_cols, drop = FALSE]
}

targets <- list(
  us_state = list(alias = c("us_state","state"),
                  vec = get("us_state", envir = env)),
  email    = list(alias = c("email"),  vec = get("email", envir = env)),
  ein      = list(alias = c("ein"),    vec = get("ein",   envir = env))
)

out <- list()
for (nm in names(targets)) {
  t <- targets[[nm]]
  real_pos <- d[d$source_label %in% t$alias, feat_cols, drop = FALSE]
  pos_feat <- rbind(boot_features(t$vec, B = 60), real_pos)
  neg_feat <- neg_sample(t$alias, n = 500)
  tf  <- top_features(pos_feat, neg_feat, k = 12)
  fit <- fit_logit(tf, k = 6)
  out[[nm]] <- list(n_pos = nrow(pos_feat), n_real_pos = nrow(real_pos),
                    n_neg = nrow(neg_feat), top = tf$top, fit = fit)
  cat("\n==============================\n", nm,
      sprintf("  (pos=%d [real=%d], neg=%d)\n", nrow(pos_feat), nrow(real_pos), nrow(neg_feat)))
  print(tf$top, row.names = FALSE)
  cat("logit top-6 accuracy:", fit$accuracy, "\n")
  print(fit$coef)
}
saveRDS(out, "data-raw/model_feature_demo.rds")
cat("\nWrote data-raw/model_feature_demo.rds\n")
