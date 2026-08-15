## data-raw/train_router.R --------------------------------------------------
## Train the LEARNED ROUTER shipped in inst/extdata/router_xgb.rds and consumed
## by guess_data_type()'s Stage-1 shortlist (R/02-01-guess-data-type.R).
##
## Parity is the whole point: features are extracted with the PACKAGE extractor
## fx_extract_features() (R/10-fx-features.R) -- the exact function that runs at
## inference -- so there is no train/serve skew (the bug that made the first
## xgboost attempt score at chance). The model predicts semantic_type_id; the
## verifier then confirms a leaf among the shortlisted ids.
##
##   Rscript data-raw/train_router.R          # full build (~few min) + save
##   Rscript data-raw/train_router.R --quick  # 400-case smoke test, no save
## ---------------------------------------------------------------------------
suppressMessages({ library(jsonlite); library(xgboost) })
args  <- commandArgs(trailingOnly = TRUE)
QUICK <- "--quick" %in% args

## load the package (functions + sysdata lexicons) into the global env
e <- globalenv(); load("R/sysdata.rda", envir = e)
for (f in list.files("R", "[.]R$", full.names = TRUE)) try(sys.source(f, envir = e), silent = TRUE)

BANKS <- c("dev/bank_sherlock", "dev/bank_sherlock_3k", "dev/bank_temporal")
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

recon <- function(o) {
  d <- o$values$data
  vals <- vapply(d, function(z) as.character(z$value), "")
  cnts <- vapply(d, function(z) as.integer(z$count), 1L)
  cnts[is.na(cnts) | cnts < 1] <- 1L
  if (sum(cnts) > 2000) cnts <- pmax(1L, round(cnts * 2000 / sum(cnts)))  # bound cost
  rep(vals, cnts)
}

files <- unlist(lapply(BANKS, function(d) list.files(d, "[.]json$", full.names = TRUE)))
if (QUICK) { set.seed(1); files <- sample(files, 400) }
cat("cases:", length(files), if (QUICK) "(QUICK)" else "", "\n")

feat <- vector("list", length(files)); lab <- vector("list", length(files)); nbad <- 0L
t0 <- proc.time()[3]
for (i in seq_along(files)) {
  o <- tryCatch(fromJSON(files[i], simplifyVector = FALSE), error = function(x) NULL)
  if (is.null(o)) { nbad <- nbad + 1L; next }
  v  <- tryCatch(recon(o), error = function(x) character(0))
  ft <- tryCatch(as.list(fx_extract_features(v)), error = function(x) NULL)
  if (is.null(ft) || !length(v)) { nbad <- nbad + 1L; next }
  feat[[i]] <- ft
  lab[[i]]  <- data.frame(
    semantic_type_id = o$label$semantic_type_id %||% NA,
    data_type        = o$label$data_type        %||% NA,
    semantic_family  = o$label$semantic_family   %||% NA,
    semantic_type    = o$label$semantic_type     %||% NA,
    match_kind       = o$label$match_kind        %||% NA,
    stringsAsFactors = FALSE)
  if (i %% 400 == 0) cat(sprintf("  %d/%d  (%.0fs)\n", i, length(files), proc.time()[3]-t0))
}
keep <- !vapply(feat, is.null, logical(1))
feat <- feat[keep]; lab <- do.call(rbind, lab[keep])
cat("extracted:", length(feat), " bad:", nbad, sprintf(" (%.0fs)\n", proc.time()[3]-t0))

## align feature columns (block gating can vary), numeric matrix
allnm <- Reduce(union, lapply(feat, names))
F <- do.call(rbind, lapply(feat, function(r) {
  v <- setNames(rep(NA_real_, length(allnm)), allnm)
  nm <- intersect(names(r), allnm); v[nm] <- as.numeric(unlist(r[nm])); v }))
F <- as.data.frame(F)
F <- F[, vapply(F, function(c){ x<-c[is.finite(c)]; isTRUE(length(x)>1 && stats::sd(x)>0) }, logical(1)), drop=FALSE]
medians <- vapply(F, function(c) { m <- stats::median(c, na.rm=TRUE); if (is.finite(m)) m else 0 }, numeric(1))
for (j in names(F)) F[[j]][!is.finite(F[[j]])] <- medians[[j]]
Xm <- as.matrix(F)

## drop classes with <2 cases (can't stratify / meaningless), encode label
lab$semantic_type_id[is.na(lab$semantic_type_id)] <- "UNK"
tab <- table(lab$semantic_type_id); ok <- lab$semantic_type_id %in% names(tab)[tab >= 2]
Xm <- Xm[ok, , drop=FALSE]; lab <- lab[ok, , drop=FALSE]
y  <- factor(lab$semantic_type_id); LV <- levels(y); K <- length(LV)
yi <- as.integer(y) - 1L
cat(sprintf("matrix: %d cases x %d features, %d semantic_type_id classes\n", nrow(Xm), ncol(Xm), K))

NROUNDS <- 120L
params <- list(objective="multi:softprob", num_class=K, eval_metric="mlogloss",
               nthread=0, max_depth=6, eta=0.15, subsample=0.8,
               colsample_bytree=0.5, min_child_weight=2)

## 3-fold OOF for an honest shortlist-recall estimate (folds kept low: the CV is
## only for reporting; the shipped model is the single full-data fit below)
set.seed(1); Kf <- 3; folds <- sample(rep(1:Kf, length.out=nrow(Xm)))
oof <- matrix(0, nrow(Xm), K, dimnames=list(NULL, LV))
for (k in 1:Kf) {
  tr <- folds != k; te <- folds == k
  fit <- xgb.train(params, xgb.DMatrix(Xm[tr,,drop=FALSE], label=yi[tr]), nrounds=NROUNDS, verbose=0)
  p <- predict(fit, Xm[te,,drop=FALSE], reshape=TRUE)
  if (!is.matrix(p)) p <- matrix(p, ncol=K, byrow=TRUE)
  oof[te,] <- p
}
truth <- as.character(y); pred <- LV[max.col(oof, ties.method="first")]
inK <- function(kk) mean(vapply(seq_len(nrow(oof)), function(i){
  tp <- oof[i, truth[i]]; sum(oof[i,] > tp) < kk }, TRUE))
cat(sprintf("\nOOF semantic_type_id  top-1=%.3f  top-3=%.3f  top-5=%.3f  top-8=%.3f\n",
            mean(pred==truth), inK(3), inK(5), inK(8)))
cat("top-1 by match_kind:\n"); print(round(tapply(pred==truth, lab$match_kind, mean, na.rm=TRUE), 3))

if (!QUICK) {
  fit_full <- xgb.train(params, xgb.DMatrix(Xm, label=yi), nrounds=NROUNDS, verbose=0)
  art <- list(
    raw = xgb.save.raw(fit_full, raw_format="ubj"),
    features = colnames(Xm), levels = LV, medians = medians,
    num_class = K, params = params, nrounds = NROUNDS,
    n_train = nrow(Xm), extractor_version = FEATURE_EXTRACTOR_VERSION,
    oof = list(top1=mean(pred==truth), top5=inK(5), top8=inK(8)))
  if (!dir.exists("inst/extdata")) dir.create("inst/extdata", recursive=TRUE)
  saveRDS(art, "inst/extdata/router_xgb.rds")
  imp <- xgb.importance(model=fit_full, feature_names=colnames(Xm))
  cat("\nsaved inst/extdata/router_xgb.rds  (", length(art$raw), "bytes model )\n")
  cat("top 15 features by gain:\n"); print(imp[1:15, c("Feature","Gain")])
}
